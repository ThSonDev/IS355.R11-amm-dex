// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Interface of AMMRouter (user entry point), ARCHITECTURE 4.3.
interface IAMMRouter {
    /// @notice Emitted per swap with the data the backend and History page need.
    event SwapExecuted(
        address indexed trader,
        address indexed tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 feeAmount,
        uint256 reserveInBefore,
        uint256 reserveOutBefore,
        address to
    );

    /// @notice block.timestamp is past the deadline.
    error Expired();
    /// @notice Swap output is below amountOutMin.
    error InsufficientOutput();
    /// @notice Token A amount is below amountAMin.
    error InsufficientAAmount();
    /// @notice Token B amount is below amountBMin.
    error InsufficientBAmount();
    /// @notice Pool is empty or the output is not below the reserve.
    error InsufficientLiquidity();
    /// @notice An amount argument is zero.
    error ZeroAmount();
    /// @notice tokenIn is not one of the pair tokens.
    error InvalidToken();

    /// @notice Add liquidity at the current reserve ratio.
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Swap an exact input amount of tokenIn.
    function swapTokens(address tokenIn, uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline)
        external
        returns (uint256 amountOut);

    /// @notice Burn LP (approve the Router first) and receive both tokens.
    function removeLiquidity(uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline)
        external
        returns (uint256 amountA, uint256 amountB);

    /// @notice Output amount for an exact input, after fee.
    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256);

    /// @notice Equivalent amount of B for amountA at the given reserves.
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256);
}
