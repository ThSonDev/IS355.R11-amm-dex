// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {AMMRouter} from "../../src/AMMRouter.sol";
import {TestToken} from "../../src/TestToken.sol";

/// @dev Bounded add/swap/remove/donate by several actors. After each op it checks, with exact integer math,
///      that k and sqrt(k)/totalSupply did not decrease (they are only allowed to rise through fees and rounding).
contract Handler is Test {
    TestToken public a;
    TestToken public b;
    AMMPair public pair;
    AMMRouter public router;
    address[] public actors;

    bool public kDecreased; // across swaps (router and raw pair swaps)
    bool public feeSkipped; // a swap passed without satisfying the fee-adjusted k check of ARCHITECTURE section 3
    bool public perLpDecreased; // sqrt(k)/S across every op
    uint256 public adds;
    uint256 public removes;
    uint256 public swaps;
    uint256 public rawSwapsTried;
    uint256 public rawSwapsOk;

    constructor(TestToken _a, TestToken _b, AMMPair _pair, AMMRouter _router) {
        (a, b, pair, router) = (_a, _b, _pair, _router);
        for (uint256 i = 0; i < 3; i++) {
            address u = makeAddr(string.concat("actor", vm.toString(i)));
            actors.push(u);
            vm.startPrank(u);
            _a.approve(address(_router), type(uint256).max);
            _b.approve(address(_router), type(uint256).max);
            _pair.approve(address(_router), type(uint256).max);
            vm.stopPrank();
        }
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function _state() internal view returns (uint256 k, uint256 s) {
        (uint256 r0, uint256 r1) = pair.getReserves();
        return (r0 * r1, pair.totalSupply());
    }

    /// @dev k/S^2 (= (sqrt(k)/S)^2) must not fall; mulDiv avoids the 256-bit overflow of cross-multiplying.
    function _checkPerLp(uint256 kOld, uint256 sOld, uint256 kNew, uint256 sNew) internal {
        if (Math.mulDiv(kNew, 1e36, sNew * sNew) < Math.mulDiv(kOld, 1e36, sOld * sOld)) perLpDecreased = true;
    }

    /// @dev Spec re-implemented independently of the pair: (B0*1e4 - in0*f) * (B1*1e4 - in1*f) >= r0*r1*1e8.
    function _checkFee(uint256 r0, uint256 r1, uint256 out0, uint256 out1) internal {
        (uint256 b0, uint256 b1) = pair.getReserves(); // equals balances right after an op
        uint256 in0 = b0 > r0 - out0 ? b0 - (r0 - out0) : 0;
        uint256 in1 = b1 > r1 - out1 ? b1 - (r1 - out1) : 0;
        uint256 f = pair.feeBps();
        if ((b0 * 10000 - in0 * f) * (b1 * 10000 - in1 * f) < r0 * r1 * 1e8) feeSkipped = true;
    }

    function addLiquidity(uint256 seed, uint256 amtA, uint256 amtB) external {
        address u = _actor(seed);
        amtA = bound(amtA, 1e6, 1e24);
        amtB = bound(amtB, 1e6, 1e24);
        (uint256 k0, uint256 s0) = _state();
        vm.prank(u);
        try router.addLiquidity(amtA, amtB, 0, 0, u, block.timestamp) {
            adds++;
        } catch {
            return;
        }
        (uint256 k1, uint256 s1) = _state();
        _checkPerLp(k0, s0, k1, s1);
    }

    function removeLiquidity(uint256 seed, uint256 fraction) external {
        address u = _actor(seed);
        uint256 lp = pair.balanceOf(u);
        if (lp == 0) return;
        uint256 amount = bound(fraction, 1, lp);
        (uint256 k0, uint256 s0) = _state();
        vm.prank(u);
        try router.removeLiquidity(amount, 0, 0, u, block.timestamp) {
            removes++;
        } catch {
            return;
        }
        (uint256 k1, uint256 s1) = _state();
        _checkPerLp(k0, s0, k1, s1);
    }

    function swap(uint256 seed, bool zeroForOne, uint256 amountIn) external {
        address u = _actor(seed);
        (uint256 r0, uint256 r1) = pair.getReserves();
        amountIn = bound(amountIn, 1e3, (zeroForOne ? r0 : r1) / 2 + 1e3);
        (uint256 k0, uint256 s0) = _state();
        vm.prank(u);
        try router.swapTokens(zeroForOne ? address(a) : address(b), amountIn, 0, u, block.timestamp) returns (
            uint256 out
        ) {
            swaps++;
            _checkFee(r0, r1, zeroForOne ? 0 : out, zeroForOne ? out : 0);
        } catch {
            return;
        }
        (uint256 k1, uint256 s1) = _state();
        if (k1 < k0) kDecreased = true;
        _checkPerLp(k0, s0, k1, s1);
    }

    /// @dev Talks to the pair directly with an arbitrary requested output, so a weakened k-check would let a
    ///      k-reducing swap through. Failed attempts leave the input in the pair as a donation.
    function rawSwap(uint256 seed, bool zeroForOne, uint256 amountIn, uint256 outPpm) external {
        address u = _actor(seed);
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 rIn = zeroForOne ? r0 : r1;
        uint256 rOut = zeroForOne ? r1 : r0;
        amountIn = bound(amountIn, 1, rIn);
        // output requested as a share of the fee-free constant-product output, from 90% to 110%
        uint256 free = amountIn * rOut / (rIn + amountIn);
        uint256 out = free * bound(outPpm, 900_000, 1_100_000) / 1_000_000;
        if (out == 0 || out >= rOut) return;
        rawSwapsTried++;
        (uint256 k0, uint256 s0) = _state();
        vm.startPrank(u);
        (zeroForOne ? a : b).transfer(address(pair), amountIn);
        try pair.swap(zeroForOne ? 0 : out, zeroForOne ? out : 0, u) {
            rawSwapsOk++;
            _checkFee(r0, r1, zeroForOne ? 0 : out, zeroForOne ? out : 0);
            (uint256 k1, uint256 s1) = _state();
            if (k1 < k0) kDecreased = true;
            _checkPerLp(k0, s0, k1, s1);
        } catch {}
        vm.stopPrank();
    }

    function donate(uint256 seed, bool tokenA, uint256 amount) external {
        amount = bound(amount, 1, 1e22);
        vm.prank(_actor(seed));
        (tokenA ? a : b).transfer(address(pair), amount);
    }
}
