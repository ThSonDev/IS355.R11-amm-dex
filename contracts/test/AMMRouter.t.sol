// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {TestToken} from "../src/TestToken.sol";
import {AMMRouter} from "../src/AMMRouter.sol";
import {IAMMRouter} from "../src/interfaces/IAMMRouter.sol";
import {IAMMPair} from "../src/interfaces/IAMMPair.sol";

contract AMMRouterTest is Test {
    TestToken a;
    TestToken b;
    AMMPair pair;
    AMMRouter router;
    address admin = makeAddr("admin");
    address user = makeAddr("user");
    address other = makeAddr("other");
    uint256 constant E = 1e18;
    uint256 constant FAR = type(uint256).max;

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

    function setUp() public {
        a = new TestToken("A", "A", address(this));
        b = new TestToken("B", "B", address(this));
        pair = new AMMPair(address(a), address(b), admin);
        router = new AMMRouter(address(pair));
        a.mint(user, 1_000_000 * E);
        b.mint(user, 1_000_000 * E);
        vm.startPrank(user);
        a.approve(address(router), FAR);
        b.approve(address(router), FAR);
        pair.approve(address(router), FAR);
        vm.stopPrank();
    }

    // --- helpers ---
    function _zero() internal view {
        assertEq(a.balanceOf(address(router)), 0);
        assertEq(b.balanceOf(address(router)), 0);
        assertEq(pair.balanceOf(address(router)), 0);
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertLe(r0, a.balanceOf(address(pair)));
        assertLe(r1, b.balanceOf(address(pair)));
    }

    function _add(uint256 x, uint256 y) internal returns (uint256 liq) {
        vm.prank(user);
        (,, liq) = router.addLiquidity(x, y, 0, 0, user, FAR);
        _zero();
    }

    // --- addLiquidity ---
    function test_add_first_uses_desired_amounts() public {
        vm.prank(user);
        (uint256 x, uint256 y, uint256 liq) = router.addLiquidity(1000 * E, 4000 * E, 0, 0, other, FAR);
        assertEq(x, 1000 * E);
        assertEq(y, 4000 * E);
        assertEq(liq, Math.sqrt(1000 * E * 4000 * E) - 1000);
        assertEq(pair.balanceOf(other), liq);
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertEq(r0, 1000 * E);
        assertEq(r1, 4000 * E);
        _zero();
    }

    function test_add_second_takes_only_optimal_amounts_B_limits() public {
        _add(1000 * E, 1000 * E);
        uint256 aBefore = a.balanceOf(user);
        uint256 bBefore = b.balanceOf(user);
        vm.prank(user);
        (uint256 x, uint256 y,) = router.addLiquidity(500 * E, 100 * E, 0, 0, user, FAR);
        assertEq(x, 100 * E);
        assertEq(y, 100 * E);
        assertEq(aBefore - a.balanceOf(user), 100 * E); // leftover A not taken
        assertEq(bBefore - b.balanceOf(user), 100 * E);
        _zero();
    }

    function test_add_second_takes_only_optimal_amounts_A_limits() public {
        _add(1000 * E, 2000 * E);
        vm.prank(user);
        (uint256 x, uint256 y,) = router.addLiquidity(100 * E, 900 * E, 0, 0, user, FAR);
        assertEq(x, 100 * E);
        assertEq(y, 200 * E);
        _zero();
    }

    function test_add_insufficient_B_amount() public {
        _add(1000 * E, 1000 * E);
        vm.prank(user);
        vm.expectRevert(IAMMRouter.InsufficientBAmount.selector);
        router.addLiquidity(100 * E, 500 * E, 0, 101 * E, user, FAR); // bOptimal = 100 < bMin
    }

    function test_add_insufficient_A_amount() public {
        _add(1000 * E, 1000 * E);
        vm.prank(user);
        vm.expectRevert(IAMMRouter.InsufficientAAmount.selector);
        router.addLiquidity(500 * E, 100 * E, 101 * E, 0, user, FAR); // aOptimal = 100 < aMin
    }

    function test_add_zero_amount_reverts() public {
        vm.startPrank(user);
        vm.expectRevert(IAMMRouter.ZeroAmount.selector);
        router.addLiquidity(0, 1, 0, 0, user, FAR);
        vm.expectRevert(IAMMRouter.ZeroAmount.selector);
        router.addLiquidity(1, 0, 0, 0, user, FAR);
        vm.stopPrank();
    }

    function test_add_expired() public {
        vm.prank(user);
        vm.expectRevert(IAMMRouter.Expired.selector);
        router.addLiquidity(1, 1, 0, 0, user, block.timestamp - 1);
    }

    // --- removeLiquidity ---
    function test_remove_returns_tokens_and_router_holds_nothing() public {
        uint256 liq = _add(1000 * E, 4000 * E);
        uint256 supply = pair.totalSupply();
        vm.prank(user);
        (uint256 x, uint256 y) = router.removeLiquidity(liq, 0, 0, other, FAR);
        assertEq(x, liq * 1000 * E / supply);
        assertEq(y, liq * 4000 * E / supply);
        assertEq(a.balanceOf(other), x);
        assertEq(b.balanceOf(other), y);
        assertEq(pair.balanceOf(user), 0);
        _zero();
    }

    function test_remove_slippage_reverts() public {
        uint256 liq = _add(1000 * E, 1000 * E);
        vm.startPrank(user);
        vm.expectRevert(IAMMRouter.InsufficientAAmount.selector);
        router.removeLiquidity(liq, 1000 * E, 0, user, FAR);
        vm.expectRevert(IAMMRouter.InsufficientBAmount.selector);
        router.removeLiquidity(liq, 0, 1000 * E, user, FAR);
        vm.stopPrank();
    }

    function test_remove_zero_and_expired() public {
        uint256 liq = _add(1000 * E, 1000 * E);
        vm.startPrank(user);
        vm.expectRevert(IAMMRouter.ZeroAmount.selector);
        router.removeLiquidity(0, 0, 0, user, FAR);
        vm.expectRevert(IAMMRouter.Expired.selector);
        router.removeLiquidity(liq, 0, 0, user, block.timestamp - 1);
        vm.stopPrank();
    }

    // --- swapTokens / getAmountOut ---
    function test_swap_A_for_B_matches_getAmountOut_and_emits_event() public {
        _add(1000 * E, 1000 * E);
        uint256 quoted = router.getAmountOut(address(a), 100 * E);
        assertEq(quoted, 90661089388014913158);
        uint256 before = b.balanceOf(other);

        vm.expectEmit(true, true, false, true);
        emit SwapExecuted(
            user, address(a), address(b), 100 * E, quoted, 100 * E * 30 / 10000, 1000 * E, 1000 * E, other
        );
        vm.prank(user);
        uint256 out = router.swapTokens(address(a), 100 * E, quoted, other, FAR);

        assertEq(out, quoted);
        assertEq(b.balanceOf(other) - before, quoted);
        _zero();
    }

    function test_swap_B_for_A_reserve_order_and_fee_in_tokenIn() public {
        _add(1000 * E, 3000 * E);
        uint256 quoted = router.getAmountOut(address(b), 300 * E);
        vm.expectEmit(true, true, false, true);
        emit SwapExecuted(user, address(b), address(a), 300 * E, quoted, 300 * E * 30 / 10000, 3000 * E, 1000 * E, user);
        vm.prank(user);
        uint256 out = router.swapTokens(address(b), 300 * E, 0, user, FAR);
        assertEq(out, quoted);
        _zero();
    }

    function test_swap_uses_current_fee_from_pair() public {
        _add(1000 * E, 1000 * E);
        uint256 q30 = router.getAmountOut(address(a), 100 * E);
        vm.prank(admin);
        pair.setFee(100);
        uint256 q100 = router.getAmountOut(address(a), 100 * E);
        assertLt(q100, q30);
        assertEq(q100, 100 * E * 9900 * 1000 * E / (1000 * E * 10000 + 100 * E * 9900));
        vm.prank(user);
        assertEq(router.swapTokens(address(a), 100 * E, q100, user, FAR), q100);
    }

    function test_swap_slippage_reverts() public {
        _add(1000 * E, 1000 * E);
        uint256 q = router.getAmountOut(address(a), 100 * E);
        vm.prank(user);
        vm.expectRevert(IAMMRouter.InsufficientOutput.selector);
        router.swapTokens(address(a), 100 * E, q + 1, user, FAR);
    }

    function test_swap_invalid_token() public {
        _add(1000 * E, 1000 * E);
        vm.prank(user);
        vm.expectRevert(IAMMRouter.InvalidToken.selector);
        router.swapTokens(address(0xBEEF), 1, 0, user, FAR);
        vm.expectRevert(IAMMRouter.InvalidToken.selector);
        router.getAmountOut(address(0xBEEF), 1);
    }

    function test_swap_zero_amount_and_expired() public {
        _add(1000 * E, 1000 * E);
        vm.startPrank(user);
        vm.expectRevert(IAMMRouter.ZeroAmount.selector);
        router.swapTokens(address(a), 0, 0, user, FAR);
        vm.expectRevert(IAMMRouter.Expired.selector);
        router.swapTokens(address(a), 1 * E, 0, user, block.timestamp - 1);
        vm.stopPrank();
    }

    function test_deadline_equal_to_timestamp_is_allowed() public {
        _add(1000 * E, 1000 * E);
        vm.prank(user);
        router.swapTokens(address(a), 1 * E, 0, user, block.timestamp);
    }

    function test_swap_on_empty_pool_reverts_insufficient_liquidity() public {
        vm.prank(user);
        vm.expectRevert(IAMMRouter.InsufficientLiquidity.selector);
        router.swapTokens(address(a), 1 * E, 0, user, FAR);
        vm.expectRevert(IAMMRouter.InsufficientLiquidity.selector);
        router.getAmountOut(address(b), 1 * E);
    }

    function test_swap_to_pool_token_bubbles_pair_error() public {
        _add(1000 * E, 1000 * E);
        vm.prank(user);
        vm.expectRevert(IAMMPair.InvalidTo.selector);
        router.swapTokens(address(a), 1 * E, 0, address(b), FAR);
    }

    // --- quote ---
    function test_quote() public {
        assertEq(router.quote(100, 1000, 2000), 200);
        assertEq(router.quote(1, 3, 2), 0); // rounds down
        vm.expectRevert(IAMMRouter.InsufficientLiquidity.selector);
        router.quote(1, 0, 1);
        vm.expectRevert(IAMMRouter.InsufficientLiquidity.selector);
        router.quote(1, 1, 0);
    }

    // --- flows ---
    function test_full_flow_add_swap_remove_lp_value_grows() public {
        uint256 liq = _add(1000 * E, 1000 * E);
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 perLpBefore = Math.sqrt(r0 * r1) * 1e18 / pair.totalSupply();

        vm.startPrank(user);
        router.swapTokens(address(a), 100 * E, 0, user, FAR);
        router.swapTokens(address(b), 50 * E, 0, user, FAR);
        router.swapTokens(address(a), 20 * E, 0, user, FAR);
        vm.stopPrank();
        _zero();

        (r0, r1) = pair.getReserves();
        assertGt(Math.sqrt(r0 * r1) * 1e18 / pair.totalSupply(), perLpBefore); // fees raise sqrt(k)/S

        vm.prank(user);
        (uint256 x, uint256 y) = router.removeLiquidity(liq, 0, 0, user, FAR);
        assertGt(x + y, 0);
        _zero();
    }

    function testFuzz_getAmountOut_equals_actual_output(uint256 amountIn, bool dir) public {
        _add(1000 * E, 2500 * E);
        amountIn = bound(amountIn, 1e6, 100_000 * E);
        address tin = dir ? address(a) : address(b);
        TestToken tout = dir ? b : a;
        uint256 quoted = router.getAmountOut(tin, amountIn);
        uint256 before = tout.balanceOf(user);
        vm.prank(user);
        router.swapTokens(tin, amountIn, quoted, user, FAR);
        assertEq(tout.balanceOf(user) - before, quoted);
        _zero();
    }
}
