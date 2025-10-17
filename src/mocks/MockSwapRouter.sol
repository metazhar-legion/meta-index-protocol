// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "../interfaces/ISwapRouter.sol";

/**
 * @title MockSwapRouter
 * @notice Mock Uniswap V3 router for testing
 * @dev Simulates swaps with configurable exchange rates
 */
contract MockSwapRouter is ISwapRouter {
    using SafeERC20 for IERC20;

    // ============ STATE VARIABLES ============

    // Exchange rate: tokenOut per tokenIn (scaled by 1e18)
    mapping(address => mapping(address => uint256)) public exchangeRates;

    // Slippage simulation (basis points, 10000 = 100%)
    uint256 public slippage = 0;

    // Track swap history for testing
    struct SwapHistory {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 timestamp;
    }

    SwapHistory[] public swapHistory;

    // ============ ERRORS ============

    error InsufficientOutput();
    error ExcessiveInput();
    error DeadlineExpired();
    error InvalidExchangeRate();

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Set exchange rate between two tokens
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param rate Exchange rate (scaled by 1e18)
     */
    function setExchangeRate(address tokenIn, address tokenOut, uint256 rate) external {
        exchangeRates[tokenIn][tokenOut] = rate;
    }

    /**
     * @notice Set slippage for testing (in basis points)
     * @param _slippage Slippage amount (e.g., 100 = 1%)
     */
    function setSlippage(uint256 _slippage) external {
        slippage = _slippage;
    }

    // ============ SWAP FUNCTIONS ============

    /**
     * @notice Swap exact input for output
     * @param params Swap parameters
     * @return amountOut Amount of output tokens received
     */
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        if (block.timestamp > params.deadline) revert DeadlineExpired();

        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        if (rate == 0) revert InvalidExchangeRate();

        // Calculate output amount with slippage
        amountOut = (params.amountIn * rate) / 1e18;
        amountOut = (amountOut * (10000 - slippage)) / 10000;

        if (amountOut < params.amountOutMinimum) revert InsufficientOutput();

        // Transfer tokens
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenOut).safeTransfer(params.recipient, amountOut);

        // Record swap
        swapHistory.push(
            SwapHistory({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                amountIn: params.amountIn,
                amountOut: amountOut,
                timestamp: block.timestamp
            })
        );

        return amountOut;
    }

    /**
     * @notice Swap for exact output
     * @param params Swap parameters
     * @return amountIn Amount of input tokens used
     */
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {
        if (block.timestamp > params.deadline) revert DeadlineExpired();

        uint256 rate = exchangeRates[params.tokenIn][params.tokenOut];
        if (rate == 0) revert InvalidExchangeRate();

        // Calculate input amount needed (with slippage)
        amountIn = (params.amountOut * 1e18) / rate;
        amountIn = (amountIn * (10000 + slippage)) / 10000;

        if (amountIn > params.amountInMaximum) revert ExcessiveInput();

        // Transfer tokens
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(params.tokenOut).safeTransfer(params.recipient, params.amountOut);

        // Record swap
        swapHistory.push(
            SwapHistory({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                amountIn: amountIn,
                amountOut: params.amountOut,
                timestamp: block.timestamp
            })
        );

        return amountIn;
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get swap history length
     * @return length Number of swaps recorded
     */
    function getSwapHistoryLength() external view returns (uint256) {
        return swapHistory.length;
    }

    /**
     * @notice Get swap history at index
     * @param index History index
     * @return history Swap history entry
     */
    function getSwapHistory(uint256 index) external view returns (SwapHistory memory) {
        return swapHistory[index];
    }

    /**
     * @notice Fund the router with tokens for testing
     * @param token Token to fund
     * @param amount Amount to fund
     */
    function fundRouter(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }
}
