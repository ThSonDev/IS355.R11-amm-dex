// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {TestToken} from "../src/TestToken.sol";
import {IAMMPair} from "../src/interfaces/IAMMPair.sol";

contract AMMPairTest is Test {
    TestToken a;
    TestToken b;
    AMMPair pair;
    address admin = makeAddr("admin");
    address lp = makeAddr("lp");
    address trader = makeAddr("trader");
    address constant DEAD = address(0xdead);
    uint256 constant E = 1e18;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event FeeUpdated(uint16 oldFeeBps, uint16 newFeeBps);

    function setUp() public {
        a = new TestToken("A", "A", address(this));
        b = new TestToken("B", "B", address(this));
        pair = new AMMPair(address(a), address(b), admin);
        a.mint(lp, 1_000_000 * E);
        b.mint(lp, 1_000_000 * E);
        a.mint(trader, 1_000_000 * E);
        b.mint(trader, 1_000_000 * E);
    }

    // --- helpers ---
    function _add(uint256 x, uint256 y) internal returns (uint256 liq) {
        vm.startPrank(lp);
        a.transfer(address(pair), x);
        b.transfer(address(pair), y);
        liq = pair.mint(lp);
        vm.stopPrank();
        _inv();
    }

    /// @dev Output of an exact-input swap per ARCHITECTURE section 3.
    function _out(uint256 amountIn, uint256 rIn, uint256 rOut) internal view returns (uint256) {
        uint256 w = amountIn * (10000 - pair.feeBps());
        return w * rOut / (rIn * 10000 + w);
    }

    function _swap0to1(uint256 amountIn, uint256 out) internal {
        vm.startPrank(trader);
        a.transfer(address(pair), amountIn);
        pair.swap(0, out, trader);
        vm.stopPrank();
        _inv();
    }

    function _swap1to0(uint256 amountIn, uint256 out) internal {
        vm.startPrank(trader);
        b.transfer(address(pair), amountIn);
        pair.swap(out, 0, trader);
        vm.stopPrank();
        _inv();
    }

    /// @dev reserve <= balanceOf and reserves tracked
    function _inv() internal view {
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertLe(r0, a.balanceOf(address(pair)));
        assertLe(r1, b.balanceOf(address(pair)));
    }

    function _k() internal view returns (uint256) {
        (uint256 r0, uint256 r1) = pair.getReserves();
        return r0 * r1;
    }

    // --- constructor ---
    function test_constructor() public view {
        assertEq(pair.token0(), address(a));
        assertEq(pair.token1(), address(b));
        assertEq(pair.feeBps(), 30);
        assertEq(pair.MAX_FEE_BPS(), 100);
        assertEq(pair.MINIMUM_LIQUIDITY(), 1000);
        assertEq(pair.name(), "AMM LP");
        assertEq(pair.symbol(), "AMM-LP");
        assertTrue(pair.hasRole(pair.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(pair.hasRole(pair.FEE_SETTER_ROLE(), admin));
        assertFalse(pair.hasRole(pair.FEE_SETTER_ROLE(), address(this)));
    }

    // --- mint ---
    function test_mint_first_locks_minimum_liquidity() public {
        vm.startPrank(lp);
        a.transfer(address(pair), 1000 * E);
        b.transfer(address(pair), 4000 * E);
        vm.expectEmit(true, true, false, true);
        emit Mint(lp, 1000 * E, 4000 * E, lp);
        uint256 liq = pair.mint(lp);
        vm.stopPrank();
        uint256 root = Math.sqrt(1000 * E * 4000 * E);
        assertEq(liq, root - 1000);
        assertEq(pair.balanceOf(lp), root - 1000);
        assertEq(pair.balanceOf(DEAD), 1000);
        assertEq(pair.totalSupply(), root);
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertEq(r0, 1000 * E);
        assertEq(r1, 4000 * E);
    }

    function test_mint_second_is_proportional() public {
        _add(1000 * E, 1000 * E);
        uint256 supply = pair.totalSupply();
        uint256 liq = _add(100 * E, 100 * E);
        assertEq(liq, 100 * E * supply / (1000 * E));
    }

    function test_mint_second_takes_min_of_both_sides() public {
        _add(1000 * E, 1000 * E);
        uint256 supply = pair.totalSupply();
        uint256 liq = _add(100 * E, 50 * E); // B side limits
        assertEq(liq, 50 * E * supply / (1000 * E));
    }

    function test_mint_first_too_small_reverts() public {
        vm.startPrank(lp);
        a.transfer(address(pair), 1000);
        b.transfer(address(pair), 1000); // sqrt = 1000 = MINIMUM_LIQUIDITY -> 0 LP
        vm.expectRevert(IAMMPair.InsufficientLiquidityMinted.selector);
        pair.mint(lp);
        vm.stopPrank();
    }

    function test_mint_nothing_deposited_reverts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InsufficientLiquidityMinted.selector);
        pair.mint(lp);
    }

    // --- burn ---
    function test_burn_returns_proportional_share() public {
        uint256 liq = _add(1000 * E, 4000 * E);
        uint256 supply = pair.totalSupply();
        vm.startPrank(lp);
        pair.transfer(address(pair), liq / 2);
        vm.expectEmit(true, true, false, true);
        emit Burn(lp, (liq / 2) * 1000 * E / supply, (liq / 2) * 4000 * E / supply, lp);
        (uint256 x, uint256 y) = pair.burn(lp);
        vm.stopPrank();
        assertEq(x, (liq / 2) * 1000 * E / supply);
        assertEq(y, (liq / 2) * 4000 * E / supply);
        assertEq(a.balanceOf(lp), 1_000_000 * E - 1000 * E + x);
        assertEq(pair.totalSupply(), supply - liq / 2);
        _inv();
    }

    function test_burn_without_lp_reverts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InsufficientLiquidityBurned.selector);
        pair.burn(lp);
    }

    function test_burn_on_empty_pool_reverts() public {
        vm.expectRevert(IAMMPair.InsufficientLiquidityBurned.selector);
        pair.burn(lp);
    }

    // --- swap ---
    function test_swap_worked_example_90_66() public {
        _add(1000 * E, 1000 * E);
        uint256 out = _out(100 * E, 1000 * E, 1000 * E);
        assertEq(out, 90661089388014913158); // ~90.66 per ARCHITECTURE section 3
        vm.prank(trader);
        a.transfer(address(pair), 100 * E);
        vm.expectEmit(true, true, false, true);
        emit Swap(address(this), 100 * E, 0, 0, out, trader);
        pair.swap(0, out, trader);
        assertEq(b.balanceOf(trader), 1_000_000 * E + out);
        _inv();
    }

    function test_swap_both_directions_and_fee_accrual() public {
        _add(1000 * E, 2000 * E);
        uint256 k0 = _k();

        (uint256 r0, uint256 r1) = pair.getReserves();
        _swap0to1(100 * E, _out(100 * E, r0, r1));
        assertEq(pair.feeAccrued0(), 100 * E * 30 / 10000);
        assertEq(pair.feeAccrued1(), 0);
        assertGe(_k(), k0);

        (r0, r1) = pair.getReserves();
        uint256 k1 = _k();
        _swap1to0(50 * E, _out(50 * E, r1, r0));
        assertEq(pair.feeAccrued0(), 100 * E * 30 / 10000);
        assertEq(pair.feeAccrued1(), 50 * E * 30 / 10000);
        assertGe(_k(), k1);
    }

    function test_swap_emits_sync() public {
        _add(1000 * E, 1000 * E);
        uint256 out = _out(10 * E, 1000 * E, 1000 * E);
        vm.prank(trader);
        a.transfer(address(pair), 10 * E);
        vm.expectEmit(false, false, false, true);
        emit Sync(1010 * E, 1000 * E - out);
        pair.swap(0, out, trader);
    }

    function test_swap_k_boundary_exact_passes_one_more_reverts() public {
        _add(1000 * E, 1000 * E);
        uint256 out = _out(100 * E, 1000 * E, 1000 * E);
        vm.prank(trader);
        a.transfer(address(pair), 100 * E);
        vm.expectRevert(IAMMPair.KInvariant.selector);
        pair.swap(0, out + 1, trader);
        pair.swap(0, out, trader); // the exact fee-adjusted amount passes
    }

    function test_swap_greedy_reverts_k() public {
        _add(1000 * E, 1000 * E);
        vm.prank(trader);
        a.transfer(address(pair), 1 * E);
        vm.expectRevert(IAMMPair.KInvariant.selector);
        pair.swap(0, 100 * E, trader);
    }

    function test_swap_no_input_reverts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InsufficientInputAmount.selector);
        pair.swap(0, 1, trader);
    }

    function test_swap_invalid_output_amounts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InvalidOutputAmounts.selector);
        pair.swap(0, 0, trader);
        vm.expectRevert(IAMMPair.InvalidOutputAmounts.selector);
        pair.swap(1, 1, trader);
    }

    function test_swap_empty_pool_reverts_insufficient_liquidity() public {
        vm.expectRevert(IAMMPair.InsufficientLiquidity.selector);
        pair.swap(0, 1, trader);
        vm.expectRevert(IAMMPair.InsufficientLiquidity.selector);
        pair.swap(1, 0, trader);
    }

    function test_swap_out_equal_reserve_reverts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InsufficientLiquidity.selector);
        pair.swap(0, 1000 * E, trader);
        vm.expectRevert(IAMMPair.InsufficientLiquidity.selector);
        pair.swap(1000 * E, 0, trader);
        vm.expectRevert(IAMMPair.InsufficientLiquidity.selector);
        pair.swap(0, 1000 * E + 1, trader);
    }

    function test_swap_to_token_address_reverts() public {
        _add(1000 * E, 1000 * E);
        vm.expectRevert(IAMMPair.InvalidTo.selector);
        pair.swap(0, 1, address(a));
        vm.expectRevert(IAMMPair.InvalidTo.selector);
        pair.swap(1, 0, address(b));
    }

    function testFuzz_swap_formula_output_keeps_k(uint256 amountIn, bool dir) public {
        _add(1000 * E, 3000 * E);
        amountIn = bound(amountIn, 1e6, 100_000 * E);
        (uint256 r0, uint256 r1) = pair.getReserves();
        uint256 k0 = _k();
        if (dir) _swap0to1(amountIn, _out(amountIn, r0, r1));
        else _swap1to0(amountIn, _out(amountIn, r1, r0));
        assertGe(_k(), k0);
    }

    // --- direct transfers ---
    function test_direct_donation_does_not_break_pair() public {
        _add(1000 * E, 1000 * E);
        vm.prank(trader);
        a.transfer(address(pair), 500 * E); // donation, reserve not updated
        (uint256 r0,) = pair.getReserves();
        assertEq(r0, 1000 * E);
        _inv();
        // later swap counts the donation as input and stays consistent
        vm.prank(trader);
        b.transfer(address(pair), 10 * E);
        pair.swap(1, 0, trader); // 1 wei of A out, donation + B in cover k
        _inv();
        // mint credits the donation to whoever calls next
        uint256 liq = _add(10 * E, 10 * E);
        assertGt(liq, 0);
    }

    // --- setFee ---
    function test_setFee_by_stranger_reverts() public {
        bytes32 role = pair.FEE_SETTER_ROLE();
        vm.prank(trader);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, trader, role));
        pair.setFee(10);
    }

    function test_setFee_above_max_reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IAMMPair.FeeTooHigh.selector, uint16(101)));
        pair.setFee(101);
    }

    function test_setFee_updates_and_applies() public {
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit FeeUpdated(30, 100);
        pair.setFee(100);
        assertEq(pair.feeBps(), 100);

        _add(1000 * E, 1000 * E);
        uint256 out = _out(100 * E, 1000 * E, 1000 * E);
        _swap0to1(100 * E, out);
        assertEq(pair.feeAccrued0(), 100 * E * 100 / 10000);

        vm.prank(admin);
        pair.setFee(0);
        assertEq(pair.feeBps(), 0);
    }
}
