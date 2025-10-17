// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {RebalanceLib} from "./libraries/RebalanceLib.sol";

/**
 * @title StrategyManager
 * @notice Manages strategy allocations for Meta Index Protocol
 * @dev Phase 1: Simple single-strategy allocation (100%)
 */
contract StrategyManager is IStrategyManager, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ STATE VARIABLES ============

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public immutable vault;
    address public immutable asset;
    address public priceOracle; // Optional - can be zero for single-asset vaults

    // Strategy tracking
    address[] private strategies;
    mapping(address => uint256) private strategyAllocations; // basis points (10000 = 100%)
    mapping(address => bool) private strategyExists;
    mapping(address => uint256) private strategyIndex;

    uint256 private constant MAX_BPS = 10_000; // 100%

    // Rebalancing parameters
    uint256 public deviationThreshold; // Deviation threshold in BPS (e.g., 500 = 5%)
    uint256 public minRebalanceAmount; // Minimum amount to trigger rebalance
    uint256 public lastRebalanceTimestamp;

    // ============ CONSTRUCTOR ============

    constructor(address _vault, address _asset, address _priceOracle) {
        if (_vault == address(0)) revert InvalidStrategy();
        if (_asset == address(0)) revert InvalidStrategy();

        vault = _vault;
        asset = _asset;
        priceOracle = _priceOracle; // Can be zero for single-asset vaults

        // Initialize rebalancing parameters
        deviationThreshold = 500; // 5% default
        minRebalanceAmount = 100e6; // $100 minimum (assuming 6 decimals)
        lastRebalanceTimestamp = block.timestamp;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, _vault); // Vault can manage strategies
    }

    // ============ STRATEGY MANAGEMENT ============

    /**
     * @notice Add a new strategy
     * @param strategy Strategy address
     * @param allocation Allocation in basis points (10000 = 100%)
     */
    function addStrategy(address strategy, uint256 allocation)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (strategy == address(0)) revert InvalidStrategy();
        if (strategyExists[strategy]) revert StrategyAlreadyExists();
        if (allocation > MAX_BPS) revert InvalidAllocation();

        // Check total allocation doesn't exceed 100%
        uint256 totalAllocation = _getTotalAllocation() + allocation;
        if (totalAllocation > MAX_BPS) revert AllocationExceeds100Percent();

        // Validate strategy interface
        IStrategy strategyContract = IStrategy(strategy);
        require(strategyContract.vault() == vault, "Strategy vault mismatch");
        require(strategyContract.asset() == asset, "Strategy asset mismatch");

        // Add strategy
        strategyIndex[strategy] = strategies.length;
        strategies.push(strategy);
        strategyAllocations[strategy] = allocation;
        strategyExists[strategy] = true;

        emit StrategyAdded(strategy, allocation);
    }

    /**
     * @notice Remove a strategy
     * @param strategy Strategy address
     */
    function removeStrategy(address strategy)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!strategyExists[strategy]) revert StrategyNotFound();

        // Ensure strategy has no funds
        IStrategy strategyContract = IStrategy(strategy);
        require(strategyContract.totalValue() == 0, "Strategy has funds");

        // Remove from array (swap with last element)
        uint256 index = strategyIndex[strategy];
        uint256 lastIndex = strategies.length - 1;

        if (index != lastIndex) {
            address lastStrategy = strategies[lastIndex];
            strategies[index] = lastStrategy;
            strategyIndex[lastStrategy] = index;
        }

        strategies.pop();
        delete strategyAllocations[strategy];
        delete strategyExists[strategy];
        delete strategyIndex[strategy];

        emit StrategyRemoved(strategy);
    }

    /**
     * @notice Update strategy allocation
     * @param strategy Strategy address
     * @param newAllocation New allocation in basis points
     */
    function updateAllocation(address strategy, uint256 newAllocation)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!strategyExists[strategy]) revert StrategyNotFound();
        if (newAllocation > MAX_BPS) revert InvalidAllocation();

        uint256 oldAllocation = strategyAllocations[strategy];

        // Check total allocation
        uint256 totalAllocation = _getTotalAllocation() - oldAllocation + newAllocation;
        if (totalAllocation > MAX_BPS) revert AllocationExceeds100Percent();

        strategyAllocations[strategy] = newAllocation;

        emit AllocationUpdated(strategy, oldAllocation, newAllocation);
    }

    // ============ ALLOCATION OPERATIONS ============

    /**
     * @notice Allocate funds to a strategy
     * @param strategy Strategy address
     * @param amount Amount to allocate
     */
    function allocateToStrategy(address strategy, uint256 amount)
        external
        onlyRole(MANAGER_ROLE)
        nonReentrant
    {
        if (!strategyExists[strategy]) revert StrategyNotFound();
        if (amount == 0) revert InvalidAllocation();

        IStrategy strategyContract = IStrategy(strategy);
        if (!strategyContract.isActive()) revert InvalidStrategy();

        // Transfer funds from vault to strategy
        IERC20(asset).safeTransferFrom(vault, address(this), amount);

        // Approve and deposit to strategy
        IERC20(asset).forceApprove(strategy, amount);
        strategyContract.deposit(amount);

        emit StrategyAllocated(strategy, amount);
    }

    /**
     * @notice Deallocate funds from a strategy
     * @param strategy Strategy address
     * @param amount Amount to deallocate
     * @param recipient Address to receive funds
     */
    function deallocateFromStrategy(address strategy, uint256 amount, address recipient)
        external
        onlyRole(MANAGER_ROLE)
        nonReentrant
    {
        if (!strategyExists[strategy]) revert StrategyNotFound();
        if (amount == 0) revert InvalidAllocation();
        if (recipient == address(0)) revert InvalidStrategy();

        // Withdraw from strategy
        IStrategy strategyContract = IStrategy(strategy);
        strategyContract.withdraw(amount, recipient);

        emit StrategyDeallocated(strategy, amount);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get all active strategies
     * @return Array of strategy addresses
     */
    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    /**
     * @notice Get strategy allocation
     * @param strategy Strategy address
     * @return Allocation in basis points
     */
    function getAllocation(address strategy) external view returns (uint256) {
        return strategyAllocations[strategy];
    }

    /**
     * @notice Check if strategy is active
     * @param strategy Strategy address
     * @return True if active
     */
    function isStrategyActive(address strategy) external view returns (bool) {
        return strategyExists[strategy];
    }

    /**
     * @notice Get total value across all strategies
     * @return Total value
     */
    function totalValue() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            IStrategy strategy = IStrategy(strategies[i]);
            total += strategy.totalValue();
        }
        return total;
    }

    /**
     * @notice Get number of strategies
     * @return Count of active strategies
     */
    function getStrategyCount() external view returns (uint256) {
        return strategies.length;
    }

    /**
     * @notice Get total value in USD (if oracle is set)
     * @return Total USD value with 8 decimals, or 0 if no oracle
     */
    function totalValueUSD() external view returns (uint256) {
        if (priceOracle == address(0)) return 0;

        uint256 totalAssets = this.totalValue();
        if (totalAssets == 0) return 0;

        return IPriceOracle(priceOracle).getValue(asset, totalAssets);
    }

    /**
     * @notice Set price oracle (admin only)
     * @param _priceOracle Address of price oracle (can be zero to disable)
     */
    function setPriceOracle(address _priceOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceOracle = _priceOracle;
    }

    // ============ INTERNAL FUNCTIONS ============

    /**
     * @dev Get total allocation across all strategies
     * @return Total allocation in basis points
     */
    function _getTotalAllocation() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            total += strategyAllocations[strategies[i]];
        }
        return total;
    }

    // ============ REBALANCING FUNCTIONS ============

    /**
     * @notice Check if portfolio needs rebalancing
     * @return needsRebalance True if rebalancing is needed
     */
    function needsRebalancing() public view returns (bool) {
        if (strategies.length == 0) return false;

        uint256 totalPortfolioValue = this.totalValue();
        if (totalPortfolioValue == 0) return false;

        // Get current values for all strategies
        uint256[] memory strategyValues = new uint256[](strategies.length);
        uint256[] memory targetAllocations = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            strategyValues[i] = IStrategy(strategies[i]).totalValue();
            targetAllocations[i] = strategyAllocations[strategies[i]];
        }

        // Calculate allocation states
        RebalanceLib.AllocationState[] memory states = RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalPortfolioValue
        );

        // Check if rebalancing is needed
        return RebalanceLib.needsRebalancing(states, deviationThreshold);
    }

    /**
     * @notice Get current allocation states for all strategies
     * @return states Array of allocation states
     */
    function getAllocationStates()
        external
        view
        returns (RebalanceLib.AllocationState[] memory states)
    {
        if (strategies.length == 0) {
            return new RebalanceLib.AllocationState[](0);
        }

        uint256 totalPortfolioValue = this.totalValue();
        if (totalPortfolioValue == 0) {
            return new RebalanceLib.AllocationState[](0);
        }

        uint256[] memory strategyValues = new uint256[](strategies.length);
        uint256[] memory targetAllocations = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            strategyValues[i] = IStrategy(strategies[i]).totalValue();
            targetAllocations[i] = strategyAllocations[strategies[i]];
        }

        return RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalPortfolioValue
        );
    }

    /**
     * @notice Execute portfolio rebalancing
     * @dev Withdraws from overweight strategies and deposits to underweight strategies
     */
    function rebalance() external onlyRole(MANAGER_ROLE) nonReentrant {
        require(strategies.length > 0, "No strategies");

        uint256 totalPortfolioValue = this.totalValue();
        require(totalPortfolioValue >= minRebalanceAmount, "Below minimum");

        // Get current values
        uint256[] memory strategyValues = new uint256[](strategies.length);
        uint256[] memory targetAllocations = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            strategyValues[i] = IStrategy(strategies[i]).totalValue();
            targetAllocations[i] = strategyAllocations[strategies[i]];
        }

        // Calculate what needs to be done
        RebalanceLib.AllocationState[] memory states = RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalPortfolioValue
        );

        require(
            RebalanceLib.needsRebalancing(states, deviationThreshold),
            "Rebalancing not needed"
        );

        // Get rebalance actions
        RebalanceLib.RebalanceAction[] memory actions = RebalanceLib.calculateRebalanceActions(
            states,
            totalPortfolioValue
        );

        // Separate into withdrawals and deposits
        (
            RebalanceLib.RebalanceAction[] memory deposits,
            RebalanceLib.RebalanceAction[] memory withdrawals
        ) = RebalanceLib.separateActions(actions);

        // Execute withdrawals first (to free up capital)
        for (uint256 i = 0; i < withdrawals.length; i++) {
            if (withdrawals[i].amount > 0) {
                IStrategy(withdrawals[i].strategy).withdraw(
                    withdrawals[i].amount,
                    address(this)
                );
            }
        }

        // Execute deposits
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].amount > 0) {
                IERC20(asset).forceApprove(deposits[i].strategy, deposits[i].amount);
                IStrategy(deposits[i].strategy).deposit(deposits[i].amount);
            }
        }

        lastRebalanceTimestamp = block.timestamp;

        emit Rebalanced(totalPortfolioValue, block.timestamp);
    }

    /**
     * @notice Set deviation threshold for rebalancing
     * @param _threshold New threshold in basis points
     */
    function setDeviationThreshold(uint256 _threshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_threshold <= 2000, "Threshold too high"); // Max 20%
        deviationThreshold = _threshold;
    }

    /**
     * @notice Set minimum rebalance amount
     * @param _minAmount New minimum amount
     */
    function setMinRebalanceAmount(uint256 _minAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minRebalanceAmount = _minAmount;
    }

    // ============ EVENTS ============

    event Rebalanced(uint256 totalValue, uint256 timestamp);
}
