// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {AMMPair} from "../../src/AMMPair.sol";
import {AMMRouter} from "../../src/AMMRouter.sol";
import {console} from "forge-std/console.sol";
import {Handler} from "./Handler.sol";
import {TestToken} from "../../src/TestToken.sol";

contract AMMInvariantTest is StdInvariant, Test {
    TestToken a;
    TestToken b;
    AMMPair pair;
    AMMRouter router;
    Handler handler;

    function setUp() public {
        a = new TestToken("A", "A", address(this));
        b = new TestToken("B", "B", address(this));
        pair = new AMMPair(address(a), address(b), makeAddr("admin"));
        router = new AMMRouter(address(pair));
        handler = new Handler(a, b, pair, router);
        for (uint256 i = 0; i < 3; i++) {
            a.mint(handler.actors(i), 1e30);
            b.mint(handler.actors(i), 1e30);
        }

        // asymmetric start: 1000 A : 4000 B
        address seed = handler.actors(0);
        vm.prank(seed);
        router.addLiquidity(1000e18, 4000e18, 0, 0, seed, block.timestamp);

        targetContract(address(handler));
        bytes4[] memory sels = new bytes4[](5);
        sels[0] = Handler.addLiquidity.selector;
        sels[1] = Handler.removeLiquidity.selector;
        sels[2] = Handler.swap.selector;
        sels[3] = Handler.rawSwap.selector;
        sels[4] = Handler.donate.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: sels}));
    }

    function invariant_reserveLeBalance() public view {
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertLe(r0, a.balanceOf(address(pair)));
        assertLe(r1, b.balanceOf(address(pair)));
    }

    function invariant_kNeverDecreasesAcrossSwaps() public view {
        assertFalse(handler.kDecreased());
    }

    function invariant_everySwapPaysTheFee() public view {
        assertFalse(handler.feeSkipped());
    }

    function invariant_valuePerLpNeverDecreases() public view {
        assertFalse(handler.perLpDecreased());
    }

    function invariant_routerHoldsNothing() public view {
        assertEq(a.balanceOf(address(router)), 0);
        assertEq(b.balanceOf(address(router)), 0);
        assertEq(pair.balanceOf(address(router)), 0);
    }

    function invariant_minimumLiquidityStaysLocked() public view {
        assertGe(pair.totalSupply(), pair.MINIMUM_LIQUIDITY());
        assertEq(pair.balanceOf(address(0xdead)), pair.MINIMUM_LIQUIDITY());
    }

    /// @dev Shows that the handler really exercised the pair (reverts inside try/catch are not counted by forge).
    function afterInvariant() public view {
        console.log("ok adds/removes/swaps", handler.adds(), handler.removes(), handler.swaps());
        console.log("raw swaps accepted/tried", handler.rawSwapsOk(), handler.rawSwapsTried());
    }
}
