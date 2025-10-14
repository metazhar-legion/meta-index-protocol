// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IStrategy
 * @notice Interface for Meta Index strategies
 */
interface IStrategy {
    /**
     * @notice Deposit assets into strategy
     * @param amount Amount to deposit
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraw assets from strategy
     * @param amount Amount to withdraw
     * @param recipient Address to receive assets
     */
    function withdraw(uint256 amount, address recipient) external;

    /**
     * @notice Get total value in USD (scaled by asset decimals)
     * @return Total value
     */
    function totalValue() external view returns (uint256);

    /**
     * @notice Get strategy name
     * @return Strategy name
     */
    function name() external view returns (string memory);

    /**
     * @notice Check if strategy is active
     * @return True if active
     */
    function isActive() external view returns (bool);

    /**
     * @notice Get the vault address
     * @return Vault address
     */
    function vault() external view returns (address);

    /**
     * @notice Get the strategy manager address
     * @return Strategy manager address
     */
    function strategyManager() external view returns (address);

    /**
     * @notice Get the asset address
     * @return Asset address
     */
    function asset() external view returns (address);
}
