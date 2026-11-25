// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {DEXRegistry} from "../src/DEXRegistry.sol";
import {IDEXRegistry} from "../src/interfaces/IDEXRegistry.sol";

contract DEXRegistryTest is Test {
    DEXRegistry reg;
    address admin = makeAddr("admin");
    address backend = makeAddr("backend");
    address auditor = makeAddr("auditor");
    address trader = makeAddr("trader");
    address stranger = makeAddr("stranger");

    bytes32 constant TX1 = keccak256("tx1");
    bytes32 constant TX2 = keccak256("tx2");
    string constant CID1 = "bafkreiexamplecid1";
    string constant CID2 = "bafkreiexamplecid2";

    event TokenListUpdated(uint256 indexed version, string cid);
    event ReceiptAttached(bytes32 indexed txHash, address indexed trader, string cid);

    function setUp() public {
        reg = new DEXRegistry(admin);
        // Read the role id first: vm.prank only applies to the next external call.
        bytes32 issuerRole = reg.RECEIPT_ISSUER_ROLE();
        vm.prank(admin);
        reg.grantRole(issuerRole, backend);
    }

    function _expectUnauthorized(address account, bytes32 role) internal {
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, role));
    }

    // --- roles ---

    function test_RoleIds() public view {
        assertEq(reg.TOKEN_LIST_MANAGER_ROLE(), keccak256("TOKEN_LIST_MANAGER_ROLE"));
        assertEq(reg.RECEIPT_ISSUER_ROLE(), keccak256("RECEIPT_ISSUER_ROLE"));
        assertEq(reg.AUDITOR_ROLE(), keccak256("AUDITOR_ROLE"));
    }

    function test_Constructor_GrantsAdminRoles() public view {
        assertTrue(reg.hasRole(reg.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(reg.hasRole(reg.TOKEN_LIST_MANAGER_ROLE(), admin));
        assertFalse(reg.hasRole(reg.RECEIPT_ISSUER_ROLE(), admin));
        assertFalse(reg.hasRole(reg.AUDITOR_ROLE(), admin));
    }

    function test_GrantRole_RevertWhen_NotAdmin() public {
        bytes32 auditorRole = reg.AUDITOR_ROLE();
        _expectUnauthorized(stranger, reg.DEFAULT_ADMIN_ROLE());
        vm.prank(stranger);
        reg.grantRole(auditorRole, stranger);
    }

    function test_AuditorRole_GrantThenRevoke() public {
        bytes32 auditorRole = reg.AUDITOR_ROLE();
        vm.prank(admin);
        reg.grantRole(auditorRole, auditor);
        assertTrue(reg.hasRole(auditorRole, auditor));

        vm.prank(admin);
        reg.revokeRole(auditorRole, auditor);
        assertFalse(reg.hasRole(auditorRole, auditor));
    }

    // --- token list ---

    function test_SetTokenList() public {
        assertEq(reg.tokenListVersion(), 0);
        assertEq(reg.tokenListCID(), "");

        vm.expectEmit(true, false, false, true, address(reg));
        emit TokenListUpdated(1, CID1);
        vm.prank(admin);
        reg.setTokenList(CID1);
        assertEq(reg.tokenListCID(), CID1);
        assertEq(reg.tokenListVersion(), 1);

        vm.prank(admin);
        reg.setTokenList(CID2);
        assertEq(reg.tokenListCID(), CID2);
        assertEq(reg.tokenListVersion(), 2);
    }

    function test_SetTokenList_RevertWhen_NoRole() public {
        _expectUnauthorized(backend, reg.TOKEN_LIST_MANAGER_ROLE());
        vm.prank(backend);
        reg.setTokenList(CID1);
    }

    function test_SetTokenList_RevertWhen_EmptyCID() public {
        vm.prank(admin);
        vm.expectRevert(IDEXRegistry.EmptyCID.selector);
        reg.setTokenList("");
    }

    function test_SetTokenList_LosesAccessAfterRevoke() public {
        bytes32 role = reg.TOKEN_LIST_MANAGER_ROLE();
        vm.prank(admin);
        reg.grantRole(role, stranger);
        vm.prank(stranger);
        reg.setTokenList(CID1);

        vm.prank(admin);
        reg.revokeRole(role, stranger);
        _expectUnauthorized(stranger, role);
        vm.prank(stranger);
        reg.setTokenList(CID2);
        assertEq(reg.tokenListCID(), CID1);
    }

    // --- receipts ---

    function test_AttachReceipt() public {
        vm.warp(1_800_000_000);
        vm.expectEmit(true, true, false, true, address(reg));
        emit ReceiptAttached(TX1, trader, CID1);
        vm.prank(backend);
        reg.attachReceipt(TX1, trader, CID1);

        IDEXRegistry.Receipt memory r = reg.getReceipt(TX1);
        assertEq(r.cid, CID1);
        assertEq(r.trader, trader);
        assertEq(r.timestamp, 1_800_000_000);
    }

    function test_AttachReceipt_RevertWhen_NoRole() public {
        // Even the admin cannot attach receipts without RECEIPT_ISSUER_ROLE.
        _expectUnauthorized(admin, reg.RECEIPT_ISSUER_ROLE());
        vm.prank(admin);
        reg.attachReceipt(TX1, trader, CID1);
    }

    function test_AttachReceipt_RevertWhen_EmptyCID() public {
        vm.prank(backend);
        vm.expectRevert(IDEXRegistry.EmptyCID.selector);
        reg.attachReceipt(TX1, trader, "");
    }

    function test_AttachReceipt_RevertWhen_ReceiptExists() public {
        vm.startPrank(backend);
        reg.attachReceipt(TX1, trader, CID1);
        vm.expectRevert(IDEXRegistry.ReceiptExists.selector);
        reg.attachReceipt(TX1, stranger, CID2);
        vm.stopPrank();

        IDEXRegistry.Receipt memory r = reg.getReceipt(TX1);
        assertEq(r.cid, CID1);
        assertEq(r.trader, trader);
    }

    function test_AttachReceipt_LosesAccessAfterRevoke() public {
        bytes32 role = reg.RECEIPT_ISSUER_ROLE();
        vm.prank(admin);
        reg.revokeRole(role, backend);

        _expectUnauthorized(backend, role);
        vm.prank(backend);
        reg.attachReceipt(TX1, trader, CID1);
    }

    function test_GetReceipt_UnknownTxReturnsEmpty() public view {
        IDEXRegistry.Receipt memory r = reg.getReceipt(TX1);
        assertEq(bytes(r.cid).length, 0);
        assertEq(r.trader, address(0));
        assertEq(r.timestamp, 0);
    }

    function test_ReceiptsOf() public {
        assertEq(reg.receiptsOf(trader).length, 0);

        vm.startPrank(backend);
        reg.attachReceipt(TX1, trader, CID1);
        reg.attachReceipt(TX2, trader, CID2);
        reg.attachReceipt(keccak256("tx3"), stranger, CID1);
        vm.stopPrank();

        bytes32[] memory list = reg.receiptsOf(trader);
        assertEq(list.length, 2);
        assertEq(list[0], TX1);
        assertEq(list[1], TX2);
        assertEq(reg.receiptsOf(stranger).length, 1);
    }
}
