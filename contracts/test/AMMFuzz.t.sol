// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {AMMRouter} from "../src/AMMRouter.sol";
import {HToken} from "./invariant/Handler.sol";

contract AMMFuzzTest is Test {
    HToken a;
    HToken b;
    AMMPair pair;
    AMMRouter router;
    address user = makeAddr("user");

    function setUp() public {
        a = new HToken("A");
        b = new HToken("B");
        pair = new AMMPair(address(a), address(b), makeAddr("admin"));
        router = new AMMRouter(address(pair));
        a.mint(user, 1e30);
        b.mint(user, 1e30);
        vm.startPrank(user);
        a.approve(address(router), type(uint256).max);
        b.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    /// @dev Random asymmetric reserves, both directions: quote equals the real output and matches the reference formula.
    function testFuzz_getAmountOut_matches_actual_and_formula(uint256 x, uint256 y, uint256 amountIn, bool dir) public {
        x = bound(x, 1e6, 1e27);
        y = bound(y, 1e6, 1e27);
        vm.prank(user);
        router.addLiquidity(x, y, 0, 0, user, block.timestamp);
        uint256 rIn = dir ? x : y;
        uint256 rOut = dir ? y : x;
        amountIn = bound(amountIn, 1e3, rIn);
        address tin = dir ? address(a) : address(b);
        HToken tout = dir ? b : a;

        uint256 quoted = router.getAmountOut(tin, amountIn);
        assertEq(quoted, amountIn * 9970 * rOut / (rIn * 10000 + amountIn * 9970));
        if (quoted == 0) return; // dust: the pair rejects zero output
        uint256 before = tout.balanceOf(user);
        vm.prank(user);
        router.swapTokens(tin, amountIn, quoted, user, block.timestamp);
        assertEq(tout.balanceOf(user) - before, quoted);
    }

    /// @dev Add then remove at an unchanged price returns at most what was deposited, losing only rounding.
    function testFuzz_add_then_remove_loses_only_rounding(uint256 x, uint256 y, uint256 x2, uint256 y2) public {
        x = bound(x, 1e9, 1e27);
        y = bound(y, 1e9, 1e27);
        vm.prank(user);
        router.addLiquidity(x, y, 0, 0, user, block.timestamp);
        x2 = bound(x2, x / 1000 + 1e9, x * 10); // not dust relative to the pool, else the add rightly mints 0 LP
        y2 = bound(y2, y / 1000 + 1e9, y * 10);
        vm.startPrank(user);
        (uint256 inA, uint256 inB, uint256 liq) = router.addLiquidity(x2, y2, 0, 0, user, block.timestamp);
        pair.approve(address(router), liq);
        (uint256 outA, uint256 outB) = router.removeLiquidity(liq, 0, 0, user, block.timestamp);
        vm.stopPrank();
        assertLe(outA, inA);
        assertLe(outB, inB);
        // loss bounded by rounding of the two proportional divisions: <= inA / liq-ish units; use 1e-6 relative + 2 wei
        assertGe(outA + inA / 1e6 + 2, inA);
        assertGe(outB + inB / 1e6 + 2, inB);
    }
}
