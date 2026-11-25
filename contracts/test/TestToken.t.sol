// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TestToken} from "../src/TestToken.sol";
import {ITestToken} from "../src/interfaces/ITestToken.sol";

contract TestTokenTest is Test {
    TestToken token;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 constant E = 1e18;

    event FaucetClaimed(address indexed user, uint256 amount);

    function setUp() public {
        token = new TestToken("TokenA", "TKA", owner);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "TokenA");
        assertEq(token.symbol(), "TKA");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.totalSupply(), 0);
    }

    // --- mint ---

    function test_Mint_ByOwner() public {
        vm.prank(owner);
        token.mint(alice, 500 * E);
        assertEq(token.balanceOf(alice), 500 * E);
        assertEq(token.totalSupply(), 500 * E);
    }

    function test_Mint_RevertWhen_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.mint(alice, 500 * E);
    }

    function test_Mint_RevertWhen_OwnershipRenounced() public {
        vm.prank(owner);
        token.renounceOwnership();
        assertEq(token.owner(), address(0));

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        token.mint(owner, 1);
    }

    // --- faucet ---

    function test_Faucet_FirstClaim() public {
        vm.expectEmit(true, false, false, true, address(token));
        emit FaucetClaimed(alice, 1_000 * E);
        vm.prank(alice);
        token.faucet();

        assertEq(token.balanceOf(alice), 1_000 * E);
        assertEq(token.lastClaimedAt(alice), block.timestamp);
    }

    function test_Faucet_RevertWhen_ClaimedAgainWithin24h() public {
        vm.prank(alice);
        token.faucet();
        uint256 availableAt = block.timestamp + 24 hours;

        vm.warp(availableAt - 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ITestToken.FaucetCooldown.selector, availableAt));
        token.faucet();
    }

    function test_Faucet_ClaimAgainAfter24h() public {
        vm.prank(alice);
        token.faucet();

        vm.warp(block.timestamp + 24 hours);
        vm.prank(alice);
        token.faucet();
        assertEq(token.balanceOf(alice), 2_000 * E);
    }

    function test_Faucet_CooldownIsPerAddress() public {
        vm.prank(alice);
        token.faucet();
        vm.prank(bob);
        token.faucet();
        assertEq(token.balanceOf(bob), 1_000 * E);
    }

    function test_Faucet_StillWorksAfterRenounce() public {
        vm.prank(owner);
        token.renounceOwnership();

        vm.prank(alice);
        token.faucet();
        assertEq(token.balanceOf(alice), 1_000 * E);
    }
}
