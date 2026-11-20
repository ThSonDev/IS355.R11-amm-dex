// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAMMPair} from "./interfaces/IAMMPair.sol";

/// @notice Constant-product pool (x*y=k) that is also the LP token "AMM-LP". Uniswap V2 style low-level API.
/// @dev Tokens must be sent to the pair before mint/burn/swap. Fee-on-transfer and rebasing tokens are unsupported.
contract AMMPair is IAMMPair, ERC20, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    uint16 public constant MAX_FEE_BPS = 100;
    address private constant DEAD = address(0xdead); // OZ v5 forbids minting to address(0)

    address public immutable token0;
    address public immutable token1;
    uint16 public feeBps = 30;
    uint256 public feeAccrued0;
    uint256 public feeAccrued1;

    uint256 private reserve0;
    uint256 private reserve1;

    constructor(address _token0, address _token1, address admin) ERC20("AMM LP", "AMM-LP") {
        token0 = _token0;
        token1 = _token1;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEE_SETTER_ROLE, admin);
    }

    function getReserves() external view returns (uint256 r0, uint256 r1) {
        return (reserve0, reserve1);
    }

    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - r0;
        uint256 amount1 = balance1 - r1;

        uint256 supply = totalSupply();
        if (supply == 0) {
            uint256 root = Math.sqrt(amount0 * amount1);
            if (root <= MINIMUM_LIQUIDITY) revert InsufficientLiquidityMinted();
            liquidity = root - MINIMUM_LIQUIDITY;
            _mint(DEAD, MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0 * supply / r0, amount1 * supply / r1);
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1, to);
    }

    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));
        uint256 supply = totalSupply();

        // supply == 0 only before the first mint: nothing to return
        amount0 = supply == 0 ? 0 : liquidity * balance0 / supply;
        amount1 = supply == 0 ? 0 : liquidity * balance1 / supply;
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);
        IERC20(token0).safeTransfer(to, amount0);
        IERC20(token1).safeTransfer(to, amount1);

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant {
        if ((amount0Out == 0) == (amount1Out == 0)) revert InvalidOutputAmounts();
        if (amount0Out >= reserve0 || amount1Out >= reserve1) revert InsufficientLiquidity();
        if (to == token0 || to == token1) revert InvalidTo();

        // optimistic transfer, then measure what came in
        if (amount0Out > 0) IERC20(token0).safeTransfer(to, amount0Out);
        if (amount1Out > 0) IERC20(token1).safeTransfer(to, amount1Out);

        uint256 amount0In;
        uint256 amount1In;
        {
            uint256 balance0 = IERC20(token0).balanceOf(address(this));
            uint256 balance1 = IERC20(token1).balanceOf(address(this));
            uint256 r0 = reserve0;
            uint256 r1 = reserve1;
            amount0In = balance0 > r0 - amount0Out ? balance0 - (r0 - amount0Out) : 0;
            amount1In = balance1 > r1 - amount1Out ? balance1 - (r1 - amount1Out) : 0;
            if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

            uint256 f = feeBps;
            uint256 b0Adj = balance0 * 10000 - amount0In * f;
            uint256 b1Adj = balance1 * 10000 - amount1In * f;
            if (b0Adj * b1Adj < r0 * r1 * 10000 ** 2) revert KInvariant();

            feeAccrued0 += amount0In * f / 10000;
            feeAccrued1 += amount1In * f / 10000;
            _update(balance0, balance1);
        }
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function setFee(uint16 newFeeBps) external onlyRole(FEE_SETTER_ROLE) {
        if (newFeeBps > MAX_FEE_BPS) revert FeeTooHigh(newFeeBps);
        emit FeeUpdated(feeBps, newFeeBps);
        feeBps = newFeeBps;
    }

    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(balance0, balance1);
    }
}
