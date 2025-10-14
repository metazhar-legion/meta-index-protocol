// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/**
 * @title BaseStrategy
 * @notice Base implementation for all strategies
 * @dev Provides common functionality and safety checks for strategy implementations
 */
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;

    // ============ STATE VARIABLES ============

    address public immutable vault;
    address public immutable strategyManager;
    address public immutable asset;
    bool public isActive;

    // ============ EVENTS ============

    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount, address recipient);
    event StrategyPaused();
    event StrategyUnpaused();

    // ============ ERRORS ============

    error OnlyVault();
    error OnlyManager();
    error StrategyNotActive();
    error ZeroAmount();
    error ZeroAddress();

    // ============ MODIFIERS ============

    modifier onlyVault() {
        if (msg.sender != vault) revert OnlyVault();
        _;
    }

    modifier onlyManager() {
        if (msg.sender != strategyManager) revert OnlyManager();
        _;
    }

    modifier whenActive() {
        if (!isActive) revert StrategyNotActive();
        _;
    }

    // ============ CONSTRUCTOR ============

    constructor(address _vault, address _manager, address _asset) {
        if (_vault == address(0)) revert ZeroAddress();
        if (_manager == address(0)) revert ZeroAddress();
        if (_asset == address(0)) revert ZeroAddress();

        vault = _vault;
        strategyManager = _manager;
        asset = _asset;
        isActive = true;
    }

    // ============ EXTERNAL FUNCTIONS ============

    /**
     * @notice Deposit assets (manager only)
     * @param amount Amount to deposit
     */
    function deposit(uint256 amount) external virtual onlyManager whenActive {
        if (amount == 0) revert ZeroAmount();
        _deposit(amount);
        emit Deposited(amount);
    }

    /**
     * @notice Withdraw assets (manager only)
     * @param amount Amount to withdraw
     * @param recipient Address to receive assets
     */
    function withdraw(uint256 amount, address recipient)
        external
        virtual
        onlyManager
    {
        if (amount == 0) revert ZeroAmount();
        if (recipient == address(0)) revert ZeroAddress();
        _withdraw(amount, recipient);
        emit Withdrawn(amount, recipient);
    }

    /**
     * @notice Get total value (must be implemented)
     * @return Total value of strategy holdings
     */
    function totalValue() external view virtual returns (uint256);

    /**
     * @notice Get strategy name (must be implemented)
     * @return Name of the strategy
     */
    function name() external view virtual returns (string memory);

    // ============ INTERNAL FUNCTIONS ============

    /**
     * @dev Internal deposit logic (must be implemented by child contracts)
     * @param amount Amount to deposit
     */
    function _deposit(uint256 amount) internal virtual;

    /**
     * @dev Internal withdraw logic (must be implemented by child contracts)
     * @param amount Amount to withdraw
     * @param recipient Address to receive assets
     */
    function _withdraw(uint256 amount, address recipient) internal virtual;

    /**
     * @notice Pause strategy (only manager)
     * @dev Prevents new deposits but allows withdrawals
     */
    function pause() external onlyManager {
        isActive = false;
        emit StrategyPaused();
    }

    /**
     * @notice Unpause strategy (only manager)
     */
    function unpause() external onlyManager {
        isActive = true;
        emit StrategyUnpaused();
    }
}
