// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {BaseStrategy} from "./BaseStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockStrategy
 * @notice Simple strategy for testing - just holds assets
 * @dev This is a basic buy-and-hold strategy with no yield generation
 */
contract MockStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    constructor(address _vault, address _manager, address _asset)
        BaseStrategy(_vault, _manager, _asset)
    {}

    /**
     * @notice Internal deposit - transfer tokens from manager to strategy
     * @param amount Amount to deposit
     */
    function _deposit(uint256 amount) internal override {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Internal withdraw - transfer tokens from strategy to recipient
     * @param amount Amount to withdraw
     * @param recipient Address to receive assets
     */
    function _withdraw(uint256 amount, address recipient) internal override {
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /**
     * @notice Get total value of strategy
     * @return Total balance of assets held
     */
    function totalValue() external view override returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    /**
     * @notice Get strategy name
     * @return Strategy name
     */
    function name() external pure override returns (string memory) {
        return "Mock Strategy";
    }
}
