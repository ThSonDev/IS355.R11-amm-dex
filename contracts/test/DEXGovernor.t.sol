// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DEXToken} from "../src/DEXToken.sol";
import {DEXGovernor} from "../src/DEXGovernor.sol";

/// @notice SC-02: OZ v5 Governor setup and the votingDelay boundary (ARCHITECTURE 4.6, 14).
/// @dev The full propose -> vote -> queue -> execute flow on AMMPair.setFee is tested in SC-21.
contract DEXGovernorTest is Test {
    // Anvil values from ARCHITECTURE 4.6
    uint48 constant VOTING_DELAY = 1;
    uint32 constant VOTING_PERIOD = 30;
    uint256 constant THRESHOLD = 1_000 ether;
    uint256 constant MIN_DELAY = 60;

    DEXToken token;
    TimelockController timelock;
    DEXGovernor governor;

    address voter = makeAddr("voter");

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string constant DESCRIPTION = "# Test proposal\n\nipfs://bafkreiexample";

    function setUp() public {
        token = new DEXToken(address(this));

        // Same order as ARCHITECTURE 4.6: timelock (temporary admin = this), governor, roles, renounce.
        timelock = new TimelockController(MIN_DELAY, new address[](0), new address[](0), address(this));
        governor = new DEXGovernor(token, timelock, VOTING_DELAY, VOTING_PERIOD, THRESHOLD);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));

        // Voter holds 10% and delegates to self; one block later the votes are checkpointed.
        token.transfer(voter, 100_000 ether);
        vm.prank(voter);
        token.delegate(voter);
        vm.roll(block.number + 1);

        // A harmless action; SC-21 uses AMMPair.setFee instead.
        targets.push(address(token));
        values.push(0);
        calldatas.push(abi.encodeCall(token.totalSupply, ()));
    }

    function _propose() internal returns (uint256 id) {
        vm.prank(voter);
        id = governor.propose(targets, values, calldatas, DESCRIPTION);
    }

    // --- configuration ---

    function test_Settings() public view {
        assertEq(governor.name(), "DEXGovernor");
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), THRESHOLD);
        assertEq(address(governor.token()), address(token));
        assertEq(governor.timelock(), address(timelock));
        assertEq(governor.quorumNumerator(), 4);
        assertEq(governor.COUNTING_MODE(), "support=bravo&quorum=for,abstain");
    }

    function test_ClockIsBlockNumber() public view {
        assertEq(governor.clock(), block.number);
        assertEq(governor.CLOCK_MODE(), "mode=blocknumber&from=default");
        assertEq(token.CLOCK_MODE(), "mode=blocknumber&from=default");
    }

    function test_Quorum_IsFourPercentOfSupply() public view {
        assertEq(governor.quorum(block.number - 1), 40_000 ether);
    }

    function test_TimelockRoles() public view {
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
        assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), address(governor)));
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(this)));
        assertEq(timelock.getMinDelay(), MIN_DELAY);
    }

    // --- votingDelay boundary: vote opens at block propose + 2 ---

    function test_VotingDelay_Boundary() public {
        // vm.getBlockNumber() instead of block.number: the compiler may reuse a cached block.number across vm.roll.
        uint256 proposeBlock = vm.getBlockNumber();
        uint256 id = _propose();

        // snapshot = proposeBlock + votingDelay; Active only when block > snapshot.
        assertEq(governor.proposalSnapshot(id), proposeBlock + VOTING_DELAY);
        assertEq(governor.proposalDeadline(id), proposeBlock + VOTING_DELAY + VOTING_PERIOD);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Pending));

        // Block N+1 (== snapshot): still Pending, voting reverts.
        vm.roll(proposeBlock + 1);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Pending));
        vm.prank(voter);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorUnexpectedProposalState.selector,
                id,
                IGovernor.ProposalState.Pending,
                bytes32(1 << uint8(IGovernor.ProposalState.Active))
            )
        );
        governor.castVote(id, 1);

        // Block N+2: Active, voting succeeds with the votes held at the snapshot.
        vm.roll(proposeBlock + 2);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Active));
        vm.prank(voter);
        governor.castVote(id, 1);
        (, uint256 forVotes,) = governor.proposalVotes(id);
        assertEq(forVotes, 100_000 ether);
    }

    function test_VotingPeriod_ClosesAfterDeadline() public {
        uint256 id = _propose();
        uint256 deadline = governor.proposalDeadline(id);

        vm.roll(deadline);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Active));

        vm.roll(deadline + 1);
        // No votes cast -> quorum not reached.
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_Propose_RevertWhen_BelowThreshold() public {
        address small = makeAddr("small");
        token.transfer(small, THRESHOLD - 1);
        vm.prank(small);
        token.delegate(small);
        vm.roll(block.number + 1);

        vm.prank(small);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernor.GovernorInsufficientProposerVotes.selector, small, THRESHOLD - 1, THRESHOLD
            )
        );
        governor.propose(targets, values, calldatas, DESCRIPTION);
    }
}
