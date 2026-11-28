// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {IStakingRewards} from "../src/interfaces/IStakingRewards.sol";
import {TestToken} from "../src/TestToken.sol";
import {DEXToken} from "../src/DEXToken.sol";

contract StakingRewardsTest is Test {
    StakingRewards staking;
    TestToken lp; // stands in for the AMMPair LP token
    DEXToken dex;

    address admin = makeAddr("timelock");
    address distributor = makeAddr("deployer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant REWARD = 400_000 ether; // 40% of DEX supply, as in the seed
    uint256 constant DURATION = 30 days;
    uint256 constant STAKE = 100 ether;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward, uint256 duration);

    function setUp() public {
        lp = new TestToken("AMM LP", "AMM-LP", address(this));
        dex = new DEXToken(distributor);
        staking = new StakingRewards(address(lp), address(dex), admin, distributor);

        address[2] memory users = [alice, bob];
        for (uint256 i = 0; i < users.length; i++) {
            lp.mint(users[i], 1_000 ether);
            vm.prank(users[i]);
            lp.approve(address(staking), type(uint256).max);
        }
    }

    // --- helpers ---

    function _fundAndNotify(uint256 reward, uint256 duration) internal {
        vm.startPrank(distributor);
        dex.transfer(address(staking), reward);
        staking.notifyRewardAmount(reward, duration);
        vm.stopPrank();
    }

    function _stake(address user, uint256 amount) internal {
        vm.prank(user);
        staking.stake(amount);
    }

    /// @dev Rounding in rewardRate / rewardPerToken loses at most a few wei per second.
    function _assertApprox(uint256 a, uint256 b) internal pure {
        assertApproxEqRel(a, b, 1e9); // 1e-9 relative
    }

    // --- setup and roles ---

    function test_Constructor() public view {
        assertEq(staking.stakingToken(), address(lp));
        assertEq(staking.rewardToken(), address(dex));
        assertTrue(staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(staking.hasRole(staking.REWARD_DISTRIBUTOR_ROLE(), admin));
        assertTrue(staking.hasRole(staking.REWARD_DISTRIBUTOR_ROLE(), distributor));
        assertFalse(staking.hasRole(staking.DEFAULT_ADMIN_ROLE(), distributor));
        assertEq(staking.REWARD_DISTRIBUTOR_ROLE(), keccak256("REWARD_DISTRIBUTOR_ROLE"));
    }

    // --- stake / withdraw ---

    function test_Stake() public {
        vm.expectEmit(true, false, false, true, address(staking));
        emit Staked(alice, STAKE);
        _stake(alice, STAKE);

        assertEq(staking.balanceOf(alice), STAKE);
        assertEq(staking.totalSupply(), STAKE);
        assertEq(lp.balanceOf(address(staking)), STAKE);
        assertEq(lp.balanceOf(alice), 1_000 ether - STAKE);
    }

    function test_Stake_RevertWhen_Zero() public {
        vm.prank(alice);
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.stake(0);
    }

    function test_Withdraw_ReturnsLP() public {
        _stake(alice, STAKE);
        vm.expectEmit(true, false, false, true, address(staking));
        emit Withdrawn(alice, 40 ether);
        vm.prank(alice);
        staking.withdraw(40 ether);

        assertEq(staking.balanceOf(alice), 60 ether);
        assertEq(staking.totalSupply(), 60 ether);
        assertEq(lp.balanceOf(alice), 1_000 ether - 60 ether);
    }

    function test_Withdraw_RevertWhen_Zero() public {
        _stake(alice, STAKE);
        vm.prank(alice);
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.withdraw(0);
    }

    function test_Withdraw_RevertWhen_MoreThanStaked() public {
        _stake(alice, STAKE);
        vm.prank(alice);
        vm.expectRevert(IStakingRewards.InsufficientStake.selector);
        staking.withdraw(STAKE + 1);
    }

    // --- reward math ---

    function test_SingleStaker_GetsWholeReward() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);

        vm.warp(vm.getBlockTimestamp() + DURATION);
        _assertApprox(staking.earned(alice), REWARD);

        vm.expectEmit(true, false, false, false, address(staking));
        emit RewardPaid(alice, 0); // amount not checked
        vm.prank(alice);
        staking.getReward();
        _assertApprox(dex.balanceOf(alice), REWARD);
        assertLe(dex.balanceOf(alice), REWARD);
        assertEq(staking.earned(alice), 0);
    }

    function test_EarnedGrowsLinearly() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);

        vm.warp(vm.getBlockTimestamp() + DURATION / 4);
        _assertApprox(staking.earned(alice), REWARD / 4);
        vm.warp(vm.getBlockTimestamp() + DURATION / 4);
        _assertApprox(staking.earned(alice), REWARD / 2);
    }

    function test_TwoEqualStakers_EarnEqually() public {
        _stake(alice, STAKE);
        _stake(bob, STAKE);
        _fundAndNotify(REWARD, DURATION);

        vm.warp(vm.getBlockTimestamp() + DURATION);
        assertEq(staking.earned(alice), staking.earned(bob));
        _assertApprox(staking.earned(alice), REWARD / 2);
    }

    function test_StakeProportional() public {
        _stake(alice, 300 ether);
        _stake(bob, 100 ether);
        _fundAndNotify(REWARD, DURATION);

        vm.warp(vm.getBlockTimestamp() + DURATION);
        _assertApprox(staking.earned(alice), REWARD * 3 / 4);
        _assertApprox(staking.earned(bob), REWARD / 4);
    }

    function test_JoinMidPeriod_EarnsForTimeStaked() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);

        // First half: alice alone gets 1/2. Second half: split equally, 1/4 each.
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);
        _stake(bob, STAKE);
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);

        _assertApprox(staking.earned(alice), REWARD * 3 / 4);
        _assertApprox(staking.earned(bob), REWARD / 4);
    }

    function test_WithdrawKeepsEarnedReward() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);

        vm.prank(alice);
        staking.withdraw(STAKE);
        uint256 earnedAtWithdraw = staking.earned(alice);
        _assertApprox(earnedAtWithdraw, REWARD / 2);

        // Nothing staked any more: reward stops growing but is still claimable.
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);
        assertEq(staking.earned(alice), earnedAtWithdraw);
        vm.prank(alice);
        staking.getReward();
        assertEq(dex.balanceOf(alice), earnedAtWithdraw);
    }

    function test_NoRewardAfterPeriodFinish() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);

        vm.warp(vm.getBlockTimestamp() + DURATION);
        uint256 atEnd = staking.earned(alice);
        vm.warp(vm.getBlockTimestamp() + 10 days);
        assertEq(staking.earned(alice), atEnd);
        assertEq(staking.lastTimeRewardApplicable(), staking.periodFinish());
    }

    function test_NoStakers_NoDivisionByZero() public {
        _fundAndNotify(REWARD, DURATION);
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);
        assertEq(staking.rewardPerToken(), 0);

        // Late staker only earns for the second half; the first half stays in the contract.
        _stake(alice, STAKE);
        vm.warp(vm.getBlockTimestamp() + DURATION / 2);
        _assertApprox(staking.earned(alice), REWARD / 2);
    }

    // --- exit ---

    function test_Exit_ReturnsLPAndReward() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);
        vm.warp(vm.getBlockTimestamp() + DURATION);

        vm.prank(alice);
        staking.exit();

        assertEq(staking.balanceOf(alice), 0);
        assertEq(staking.totalSupply(), 0);
        assertEq(lp.balanceOf(alice), 1_000 ether);
        _assertApprox(dex.balanceOf(alice), REWARD);
        assertEq(staking.earned(alice), 0);
    }

    function test_Exit_RevertWhen_NothingStaked() public {
        vm.prank(alice);
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.exit();
    }

    // --- notifyRewardAmount ---

    function test_Notify_SetsPeriod() public {
        vm.prank(distributor);
        dex.transfer(address(staking), REWARD);

        vm.expectEmit(false, false, false, true, address(staking));
        emit RewardAdded(REWARD, DURATION);
        vm.prank(distributor);
        staking.notifyRewardAmount(REWARD, DURATION);

        assertEq(staking.rewardRate(), REWARD / DURATION);
        assertEq(staking.periodFinish(), vm.getBlockTimestamp() + DURATION);
        assertEq(staking.lastUpdateTime(), vm.getBlockTimestamp());
    }

    function test_Notify_RevertWhen_NotDistributor() public {
        bytes32 role = staking.REWARD_DISTRIBUTOR_ROLE();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, role));
        staking.notifyRewardAmount(REWARD, DURATION);
    }

    function test_Notify_ByAdminTimelock() public {
        vm.prank(distributor);
        dex.transfer(address(staking), REWARD);
        vm.prank(admin);
        staking.notifyRewardAmount(REWARD, DURATION);
        assertEq(staking.periodFinish(), vm.getBlockTimestamp() + DURATION);
    }

    function test_Notify_RevertWhen_ZeroRewardOrDuration() public {
        vm.prank(distributor);
        dex.transfer(address(staking), REWARD);

        vm.startPrank(distributor);
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.notifyRewardAmount(0, DURATION);
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.notifyRewardAmount(REWARD, 0);
        // reward < duration gives a rate of 0
        vm.expectRevert(IStakingRewards.ZeroAmount.selector);
        staking.notifyRewardAmount(DURATION - 1, DURATION);
        vm.stopPrank();
    }

    function test_Notify_RevertWhen_PeriodActive() public {
        _fundAndNotify(REWARD, DURATION);
        uint256 finish = staking.periodFinish();

        vm.prank(distributor);
        dex.transfer(address(staking), REWARD);

        vm.warp(finish - 1);
        vm.prank(distributor);
        vm.expectRevert(abi.encodeWithSelector(IStakingRewards.RewardPeriodActive.selector, finish));
        staking.notifyRewardAmount(REWARD, DURATION);

        // Allowed again once the period has ended.
        vm.warp(finish);
        vm.prank(distributor);
        staking.notifyRewardAmount(REWARD, DURATION);
        assertEq(staking.periodFinish(), finish + DURATION);
    }

    function test_Notify_RevertWhen_InsufficientBalance() public {
        vm.startPrank(distributor);
        dex.transfer(address(staking), REWARD - 1 ether);
        vm.expectRevert(IStakingRewards.InsufficientRewardBalance.selector);
        staking.notifyRewardAmount(REWARD, DURATION);
        vm.stopPrank();
    }

    function test_Notify_DoesNotReuseUnclaimedRewards() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);
        vm.warp(vm.getBlockTimestamp() + DURATION);
        // Alice has ~REWARD unclaimed; the contract still holds it.
        uint256 owed = staking.earned(alice);

        // A second period funded with only part of the new reward must fail,
        // even though the raw balance (owed + new tokens) would look large enough.
        vm.startPrank(distributor);
        dex.transfer(address(staking), REWARD / 2);
        vm.expectRevert(IStakingRewards.InsufficientRewardBalance.selector);
        staking.notifyRewardAmount(REWARD, DURATION);

        // Funding the rest makes it pass.
        dex.transfer(address(staking), REWARD / 2);
        staking.notifyRewardAmount(REWARD, DURATION);
        vm.stopPrank();

        // Both periods are fully payable.
        vm.warp(vm.getBlockTimestamp() + DURATION);
        vm.prank(alice);
        staking.getReward();
        assertGe(dex.balanceOf(alice), owed);
        _assertApprox(dex.balanceOf(alice), 2 * REWARD);
        assertLe(dex.balanceOf(alice), 2 * REWARD);
    }

    function test_NoAdminWithdrawFunction() public {
        _stake(alice, STAKE);
        _fundAndNotify(REWARD, DURATION);
        // Common rescue function names must not exist.
        vm.startPrank(admin);
        (bool ok1,) = address(staking).call(abi.encodeWithSignature("recoverERC20(address,uint256)", address(lp), 1));
        (bool ok2,) = address(staking).call(abi.encodeWithSignature("withdraw(address,uint256)", admin, 1));
        vm.stopPrank();
        assertFalse(ok1);
        assertFalse(ok2);
        assertEq(lp.balanceOf(address(staking)), STAKE);
    }

    // --- fuzz: total paid never exceeds total funded ---

    function testFuzz_TotalPaidLeFunded(uint96 aliceAmt, uint96 bobAmt, uint32 bobJoin, uint32 aliceLeave) public {
        uint256 a = bound(aliceAmt, 1, 1_000 ether);
        uint256 b = bound(bobAmt, 1, 1_000 ether);
        uint256 join = bound(bobJoin, 0, DURATION);
        uint256 leave = bound(aliceLeave, 0, DURATION + 1 days);
        uint256 start = vm.getBlockTimestamp();

        _stake(alice, a);
        _fundAndNotify(REWARD, DURATION);

        // Apply the two events in time order.
        if (join <= leave) {
            vm.warp(start + join);
            _stake(bob, b);
            vm.warp(start + leave);
            vm.prank(alice);
            staking.exit();
        } else {
            vm.warp(start + leave);
            vm.prank(alice);
            staking.exit();
            vm.warp(start + join);
            _stake(bob, b);
        }

        vm.warp(start + DURATION + 1 days);
        vm.prank(bob);
        staking.exit();
        // alice may have exited already; claim anything left (no-op if zero)
        vm.prank(alice);
        staking.getReward();

        uint256 paid = dex.balanceOf(alice) + dex.balanceOf(bob);
        assertLe(paid, REWARD);
        assertEq(dex.balanceOf(address(staking)), REWARD - paid);
        // Everyone got their LP back.
        assertEq(lp.balanceOf(alice), 1_000 ether);
        assertEq(lp.balanceOf(bob), 1_000 ether);
        assertEq(staking.totalSupply(), 0);
    }
}
