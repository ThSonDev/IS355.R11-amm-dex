// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAMMPair} from "./interfaces/IAMMPair.sol";
import {IAMMRouter} from "./interfaces/IAMMRouter.sol";

/// @notice User entry point for one AMMPair: deadline, slippage and optimal-amount checks. Holds no funds.
/// @dev tokenA = pair.token0(), tokenB = pair.token1(). Tokens go from the user straight into the pair.
contract AMMRouter is IAMMRouter {
    using SafeERC20 for IERC20;

    IAMMPair private immutable pair;
    address private immutable tokenA;
    address private immutable tokenB;

    constructor(address _pair) {
        pair = IAMMPair(_pair);
        tokenA = pair.token0();
        tokenB = pair.token1();
    }

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) revert Expired();
        _;
    }

    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (amountADesired == 0 || amountBDesired == 0) revert ZeroAmount();
        (amountA, amountB) = _optimalAmounts(amountADesired, amountBDesired, amountAMin, amountBMin);
        IERC20(tokenA).safeTransferFrom(msg.sender, address(pair), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(pair), amountB);
        liquidity = pair.mint(to);
    }

    function swapTokens(address tokenIn, uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline)
        external
        ensure(deadline)
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert ZeroAmount();
        (address tokenOut, uint256 rIn, uint256 rOut) = _direction(tokenIn);
        amountOut = _amountOut(amountIn, rIn, rOut);
        if (amountOut < amountOutMin) revert InsufficientOutput();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(pair), amountIn);
        if (tokenIn == tokenA) pair.swap(0, amountOut, to);
        else pair.swap(amountOut, 0, to);
        _emitSwap(tokenIn, tokenOut, amountIn, amountOut, rIn, rOut, to);
    }

    function removeLiquidity(uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline)
        external
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        if (liquidity == 0) revert ZeroAmount();
        IERC20(address(pair)).safeTransferFrom(msg.sender, address(pair), liquidity);
        (amountA, amountB) = pair.burn(to);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256) {
        (, uint256 rIn, uint256 rOut) = _direction(tokenIn);
        return _amountOut(amountIn, rIn, rOut);
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure returns (uint256) {
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        return amountA * reserveB / reserveA;
    }

    function _emitSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 rIn,
        uint256 rOut,
        address to
    ) private {
        uint256 fee = amountIn * pair.feeBps() / 10000; // in tokenIn
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut, fee, rIn, rOut, to);
    }

    /// @dev Validates tokenIn and returns the other token plus (reserveIn, reserveOut).
    function _direction(address tokenIn) private view returns (address tokenOut, uint256 rIn, uint256 rOut) {
        (uint256 r0, uint256 r1) = pair.getReserves();
        if (tokenIn == tokenA) (tokenOut, rIn, rOut) = (tokenB, r0, r1);
        else if (tokenIn == tokenB) (tokenOut, rIn, rOut) = (tokenA, r1, r0);
        else revert InvalidToken();
    }

    function _amountOut(uint256 amountIn, uint256 rIn, uint256 rOut) private view returns (uint256) {
        if (rIn == 0 || rOut == 0) revert InsufficientLiquidity();
        uint256 amountInWithFee = amountIn * (10000 - pair.feeBps());
        return amountInWithFee * rOut / (rIn * 10000 + amountInWithFee);
    }

    /// @dev Empty pool: use the desired amounts. Otherwise keep the reserve ratio and take only what is needed.
    function _optimalAmounts(uint256 aDesired, uint256 bDesired, uint256 aMin, uint256 bMin)
        private
        view
        returns (uint256 amountA, uint256 amountB)
    {
        (uint256 rA, uint256 rB) = pair.getReserves();
        if (rA == 0 && rB == 0) return (aDesired, bDesired);
        uint256 bOptimal = quote(aDesired, rA, rB);
        if (bOptimal <= bDesired) {
            if (bOptimal < bMin) revert InsufficientBAmount();
            return (aDesired, bOptimal);
        }
        uint256 aOptimal = quote(bDesired, rB, rA);
        if (aOptimal < aMin) revert InsufficientAAmount();
        return (aOptimal, bDesired);
    }
}
