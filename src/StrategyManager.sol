// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

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

    // Strategy tracking
    address[] private strategies;
    mapping(address => uint256) private strategyAllocations; // basis points (10000 = 100%)
    mapping(address => bool) private strategyExists;
    mapping(address => uint256) private strategyIndex;

    uint256 private constant MAX_BPS = 10_000; // 100%

    // ============ CONSTRUCTOR ============

    constructor(address _vault, address _asset) {
        if (_vault == address(0)) revert InvalidStrategy();
        if (_asset == address(0)) revert InvalidStrategy();

        vault = _vault;
        asset = _asset;

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
}
