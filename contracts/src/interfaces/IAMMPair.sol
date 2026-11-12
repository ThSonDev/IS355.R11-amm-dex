// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Interface of AMMPair (core pool and LP token "AMM-LP"), ARCHITECTURE 4.2. ERC20 and AccessControl functions are not repeated.
interface IAMMPair {
    /// @notice Liquidity added; sender is the Router.
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    /// @notice Liquidity removed; sender is the Router.
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    /// @notice Swap done; sender is the Router, not the trader.
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    /// @notice Reserves updated.
    event Sync(uint256 reserve0, uint256 reserve1);
    /// @notice Swap fee changed.
    event FeeUpdated(uint16 oldFeeBps, uint16 newFeeBps);

    /// @notice Pool is empty or the requested output is not below the reserve.
    error InsufficientLiquidity();
    /// @notice Swap with both amounts out zero, or both non-zero.
    error InvalidOutputAmounts();
    /// @notice Swap recipient is token0 or token1.
    error InvalidTo();
    /// @notice Swap without any token sent in.
    error InsufficientInputAmount();
    /// @notice Swap fails the fee-adjusted k check.
    error KInvariant();
    /// @notice Mint would give zero LP.
    error InsufficientLiquidityMinted();
    /// @notice Burn would return zero tokens.
    error InsufficientLiquidityBurned();
    /// @notice New fee is above MAX_FEE_BPS.
    error FeeTooHigh(uint16 newFeeBps);

    /// @notice Role allowed to call setFee.
    function FEE_SETTER_ROLE() external view returns (bytes32);
    /// @notice LP amount locked forever on first mint.
    function MINIMUM_LIQUIDITY() external view returns (uint256);
    /// @notice Upper bound of feeBps.
    function MAX_FEE_BPS() external view returns (uint16);
    /// @notice First pool token.
    function token0() external view returns (address);
    /// @notice Second pool token.
    function token1() external view returns (address);
    /// @notice Swap fee in basis points (30 at start).
    function feeBps() external view returns (uint16);
    /// @notice Total fee collected in token0.
    function feeAccrued0() external view returns (uint256);
    /// @notice Total fee collected in token1.
    function feeAccrued1() external view returns (uint256);

    /// @notice Current reserves.
    function getReserves() external view returns (uint256 r0, uint256 r1);
    /// @notice Mint LP for tokens already sent to the pair.
    function mint(address to) external returns (uint256 liquidity);
    /// @notice Burn LP held by the pair and send the tokens to `to`.
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    /// @notice Swap tokens already sent to the pair.
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external;
    /// @notice Change the fee; FEE_SETTER_ROLE only.
    function setFee(uint16 newFeeBps) external;
}
