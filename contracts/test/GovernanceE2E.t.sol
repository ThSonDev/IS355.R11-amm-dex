// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DEXToken} from "../src/DEXToken.sol";
import {DEXGovernor} from "../src/DEXGovernor.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {TestToken} from "../src/TestToken.sol";
import {IAMMPair} from "../src/interfaces/IAMMPair.sol";

/// @notice SC-21: a fee change goes propose -> vote -> queue -> execute (ARCHITECTURE 4.6).
/// @dev The Timelock is the only holder of the Pair roles, and is configured like SC-20 does it.
contract GovernanceE2ETest is Test {
    // Anvil values from ARCHITECTURE 4.6
    uint48 constant VOTING_DELAY = 1;
    uint32 constant VOTING_PERIOD = 30;
    uint256 constant THRESHOLD = 1_000 ether;
    uint256 constant MIN_DELAY = 60;
    uint256 constant HOLDING = 100_000 ether; // 10% each, ARCHITECTURE 4.4

    uint8 constant AGAINST = 0;
    uint8 constant FOR = 1;

    string constant DESCRIPTION = "# Raise swap fee to 0.5%\n\nipfs://bafkreiexamplefeeproposal";

    DEXToken token;
    TimelockController timelock;
    DEXGovernor governor;
    AMMPair pair;

    address lp = makeAddr("lp");
    address trader = makeAddr("trader");
    address community = makeAddr("community");

    event FeeUpdated(uint16 oldFeeBps, uint16 newFeeBps);

    function setUp() public {
        token = new DEXToken(address(this));
        timelock = new TimelockController(MIN_DELAY, new address[](0), new address[](0), address(this));
        governor = new DEXGovernor(token, timelock, VOTING_DELAY, VOTING_PERIOD, THRESHOLD);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));

        TestToken a = new TestToken("TokenA", "TKA", address(this));
        TestToken b = new TestToken("TokenB", "TKB", address(this));
        pair = new AMMPair(address(a), address(b), address(timelock));

        _fund(lp, HOLDING);
        _fund(trader, HOLDING);
        _fund(community, HOLDING);
        vm.roll(vm.getBlockNumber() + 1);
    }

    function _fund(address holder, uint256 amount) internal {
        token.transfer(holder, amount);
        vm.prank(holder);
        token.delegate(holder);
    }

    function _action(uint16 newFee)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(pair);
        calldatas[0] = abi.encodeCall(AMMPair.setFee, (newFee));
    }

    function _propose(uint16 newFee) internal returns (uint256 id) {
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _action(newFee);
        vm.prank(lp);
        id = governor.propose(t, v, c, DESCRIPTION);
    }

    function _queue(uint16 newFee) internal {
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _action(newFee);
        governor.queue(t, v, c, keccak256(bytes(DESCRIPTION)));
    }

    function _execute(uint16 newFee) internal {
        (address[] memory t, uint256[] memory v, bytes[] memory c) = _action(newFee);
        governor.execute(t, v, c, keccak256(bytes(DESCRIPTION)));
    }

    function _openVoting(uint256 id) internal {
        vm.roll(governor.proposalSnapshot(id) + 1);
    }

    function _closeVoting(uint256 id) internal {
        vm.roll(governor.proposalDeadline(id) + 1);
    }

    function _vote(address voter, uint256 id, uint8 support) internal {
        vm.prank(voter);
        governor.castVote(id, support);
    }

    function _assertState(uint256 id, IGovernor.ProposalState expected) internal view {
        assertEq(uint8(governor.state(id)), uint8(expected));
    }

    /// @dev LP and Community For, Trader Against (the demo scenario of ARCHITECTURE 4.6).
    function _passProposal(uint16 newFee) internal returns (uint256 id) {
        id = _propose(newFee);
        _openVoting(id);
        _vote(lp, id, FOR);
        _vote(community, id, FOR);
        _vote(trader, id, AGAINST);
        _closeVoting(id);
    }

    // --- full flow ---

    function test_FullFlow_FeeChange() public {
        assertEq(pair.feeBps(), 30);

        uint256 id = _passProposal(50);
        (uint256 againstVotes, uint256 forVotes,) = governor.proposalVotes(id);
        assertEq(forVotes, 2 * HOLDING);
        assertEq(againstVotes, HOLDING);
        _assertState(id, IGovernor.ProposalState.Succeeded);

        _queue(50);
        _assertState(id, IGovernor.ProposalState.Queued);
        assertEq(pair.feeBps(), 30);

        vm.warp(governor.proposalEta(id));
        vm.expectEmit(address(pair));
        emit FeeUpdated(30, 50);
        _execute(50);

        _assertState(id, IGovernor.ProposalState.Executed);
        assertEq(pair.feeBps(), 50);
    }

    // --- failures ---

    /// @dev 30,000 For is below the 4% quorum (40,000), although nobody voted Against.
    function test_BelowQuorum_Defeated() public {
        address small = makeAddr("small");
        _fund(small, 30_000 ether);
        vm.roll(vm.getBlockNumber() + 1);

        uint256 id = _propose(50);
        _openVoting(id);
        _vote(small, id, FOR);
        _closeVoting(id);

        _assertState(id, IGovernor.ProposalState.Defeated);
        vm.expectPartialRevert(IGovernor.GovernorUnexpectedProposalState.selector);
        this.queueExternal(50);
    }

    /// @dev Quorum is met (For counts toward it) but Against wins.
    function test_MajorityAgainst_Defeated() public {
        uint256 id = _propose(50);
        _openVoting(id);
        _vote(lp, id, FOR);
        _vote(community, id, AGAINST);
        _vote(trader, id, AGAINST);
        _closeVoting(id);

        _assertState(id, IGovernor.ProposalState.Defeated);
    }

    function test_FeeAboveCap_ExecuteReverts() public {
        uint256 id = _passProposal(150);
        _queue(150);
        vm.warp(governor.proposalEta(id));

        vm.expectRevert(abi.encodeWithSelector(IAMMPair.FeeTooHigh.selector, uint16(150)));
        this.executeExternal(150);

        assertEq(pair.feeBps(), 30);
        _assertState(id, IGovernor.ProposalState.Queued);
    }

    function test_Execute_RevertWhen_NotQueued() public {
        uint256 id = _passProposal(50);

        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorUnexpectedProposalState.selector,
                id,
                IGovernor.ProposalState.Succeeded,
                bytes32(1 << uint8(IGovernor.ProposalState.Queued))
            )
        );
        this.executeExternal(50);

        assertEq(pair.feeBps(), 30);
        _assertState(id, IGovernor.ProposalState.Succeeded);
    }

    function test_Execute_RevertWhen_BeforeMinDelay() public {
        uint256 id = _passProposal(50);
        _queue(50);
        vm.warp(governor.proposalEta(id) - 1);

        vm.expectPartialRevert(TimelockController.TimelockUnexpectedOperationState.selector);
        this.executeExternal(50);

        assertEq(pair.feeBps(), 30);
    }

    function test_Propose_RevertWhen_BelowThreshold() public {
        address small = makeAddr("small");
        _fund(small, THRESHOLD - 1);
        vm.roll(vm.getBlockNumber() + 1);

        (address[] memory t, uint256[] memory v, bytes[] memory c) = _action(50);
        vm.prank(small);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorInsufficientProposerVotes.selector, small, THRESHOLD - 1, THRESHOLD
            )
        );
        governor.propose(t, v, c, DESCRIPTION);
    }

    function test_SetFee_Direct_RevertWhen_NotTimelock() public {
        bytes32 role = pair.FEE_SETTER_ROLE();
        address[3] memory callers = [address(this), lp, address(governor)];
        for (uint256 i = 0; i < callers.length; i++) {
            vm.prank(callers[i]);
            vm.expectRevert(
                abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, callers[i], role)
            );
            pair.setFee(50);
        }
        assertEq(pair.feeBps(), 30);
    }

    // expectRevert applies to the next call, so the multi-step helpers need one external entry point.
    function queueExternal(uint16 newFee) external {
        _queue(newFee);
    }

    function executeExternal(uint16 newFee) external {
        _execute(newFee);
    }
}
