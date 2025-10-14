// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IStrategyManager
 * @notice Interface for Meta Index Strategy Manager
 */
interface IStrategyManager {
    // ============ EVENTS ============

    event StrategyAdded(address indexed strategy, uint256 allocation);
    event StrategyRemoved(address indexed strategy);
    event StrategyAllocated(address indexed strategy, uint256 amount);
    event StrategyDeallocated(address indexed strategy, uint256 amount);
    event AllocationUpdated(address indexed strategy, uint256 oldAllocation, uint256 newAllocation);

    // ============ ERRORS ============

    error InvalidStrategy();
    error StrategyAlreadyExists();
    error StrategyNotFound();
    error InvalidAllocation();
    error AllocationExceeds100Percent();
    error InsufficientFunds();

    // ============ STRATEGY MANAGEMENT ============

    /**
     * @notice Add a new strategy
     * @param strategy Strategy address
     * @param allocation Allocation in basis points (10000 = 100%)
     */
    function addStrategy(address strategy, uint256 allocation) external;

    /**
     * @notice Remove a strategy
     * @param strategy Strategy address
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Update strategy allocation
     * @param strategy Strategy address
     * @param newAllocation New allocation in basis points
     */
    function updateAllocation(address strategy, uint256 newAllocation) external;

    /**
     * @notice Get all active strategies
     * @return Array of strategy addresses
     */
    function getStrategies() external view returns (address[] memory);

    /**
     * @notice Get strategy allocation
     * @param strategy Strategy address
     * @return Allocation in basis points
     */
    function getAllocation(address strategy) external view returns (uint256);

    /**
     * @notice Check if strategy is active
     * @param strategy Strategy address
     * @return True if active
     */
    function isStrategyActive(address strategy) external view returns (bool);

    // ============ ALLOCATION OPERATIONS ============

    /**
     * @notice Allocate funds to a strategy
     * @param strategy Strategy address
     * @param amount Amount to allocate
     */
    function allocateToStrategy(address strategy, uint256 amount) external;

    /**
     * @notice Deallocate funds from a strategy
     * @param strategy Strategy address
     * @param amount Amount to deallocate
     * @param recipient Address to receive funds
     */
    function deallocateFromStrategy(address strategy, uint256 amount, address recipient) external;

    /**
     * @notice Get total value across all strategies
     * @return Total value
     */
    function totalValue() external view returns (uint256);

    /**
     * @notice Get vault address
     * @return Vault address
     */
    function vault() external view returns (address);
}
