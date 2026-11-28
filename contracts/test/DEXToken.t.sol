// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DEXToken} from "../src/DEXToken.sol";

contract DEXTokenTest is Test {
    DEXToken token;
    address deployer = makeAddr("deployer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        token = new DEXToken(deployer);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "DEX Token");
        assertEq(token.symbol(), "DEX");
        assertEq(token.decimals(), 18);
    }

    function test_FixedSupplyMintedToRecipient() public view {
        assertEq(token.TOTAL_SUPPLY(), 1_000_000 ether);
        assertEq(token.totalSupply(), 1_000_000 ether);
        assertEq(token.balanceOf(deployer), 1_000_000 ether);
    }

    function test_NoMintFunction() public {
        // There is no public mint: a raw call with mint(address,uint256) must fail.
        (bool ok,) = address(token).call(abi.encodeWithSignature("mint(address,uint256)", alice, 1 ether));
        assertFalse(ok);
        assertEq(token.totalSupply(), 1_000_000 ether);
    }

    function test_Votes_ZeroUntilDelegated() public {
        vm.prank(deployer);
        token.transfer(alice, 100 ether);

        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.getVotes(alice), 0);
        assertEq(token.delegates(alice), address(0));

        vm.prank(alice);
        token.delegate(alice);
        assertEq(token.delegates(alice), alice);
        assertEq(token.getVotes(alice), 100 ether);
    }

    function test_Votes_FollowTransfers() public {
        vm.prank(deployer);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);

        vm.prank(alice);
        token.transfer(bob, 30 ether);
        assertEq(token.getVotes(alice), 70 ether);
        assertEq(token.getVotes(bob), 30 ether);
    }

    function test_Votes_DelegateToSomeoneElse() public {
        vm.prank(deployer);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(bob);

        assertEq(token.getVotes(alice), 0);
        assertEq(token.getVotes(bob), 100 ether);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_PastVotes_UnchangedForOldBlocks() public {
        vm.prank(deployer);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(alice);
        // vm.getBlockNumber() instead of block.number: the compiler may reuse a cached block.number across vm.roll.
        uint256 blockA = vm.getBlockNumber();

        vm.roll(blockA + 1);
        vm.prank(alice);
        token.transfer(bob, 40 ether);
        uint256 blockB = vm.getBlockNumber();

        vm.roll(blockB + 1);
        assertEq(token.getPastVotes(alice, blockA), 100 ether);
        assertEq(token.getPastVotes(alice, blockB), 60 ether);
        assertEq(token.getVotes(alice), 60 ether);
        assertEq(token.getPastTotalSupply(blockA), 1_000_000 ether);
    }

    function test_Permit() public {
        (address owner, uint256 pk) = makeAddrAndKey("owner");
        vm.prank(deployer);
        token.transfer(owner, 10 ether);

        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                bob,
                5 ether,
                token.nonces(owner),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);

        token.permit(owner, bob, 5 ether, deadline, v, r, s);
        assertEq(token.allowance(owner, bob), 5 ether);
        assertEq(token.nonces(owner), 1);
    }
}
