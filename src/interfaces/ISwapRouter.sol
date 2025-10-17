// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ISwapRouter
 * @notice Simplified interface for Uniswap V3 SwapRouter
 * @dev Phase 1D: Minimal interface for rebalancing swaps
 */
interface ISwapRouter {
    /**
     * @notice Parameters for exact input single swap
     * @param tokenIn Address of input token
     * @param tokenOut Address of output token
     * @param fee Pool fee tier (500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
     * @param recipient Address to receive output tokens
     * @param deadline Transaction deadline (unix timestamp)
     * @param amountIn Exact amount of input tokens
     * @param amountOutMinimum Minimum amount of output tokens (slippage protection)
     * @param sqrtPriceLimitX96 Price limit (0 = no limit)
     */
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice Swap exact input for output
     * @param params Swap parameters
     * @return amountOut Amount of output tokens received
     */
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @notice Parameters for exact output single swap
     * @param tokenIn Address of input token
     * @param tokenOut Address of output token
     * @param fee Pool fee tier
     * @param recipient Address to receive output tokens
     * @param deadline Transaction deadline
     * @param amountOut Exact amount of output tokens desired
     * @param amountInMaximum Maximum amount of input tokens (slippage protection)
     * @param sqrtPriceLimitX96 Price limit (0 = no limit)
     */
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice Swap for exact output
     * @param params Swap parameters
     * @return amountIn Amount of input tokens used
     */
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}
