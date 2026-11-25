// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IDEXRegistry} from "./interfaces/IDEXRegistry.sol";

/// @notice On-chain pointers to IPFS resources with role-based write access, ARCHITECTURE 4.7 and 5.
/// @dev Holds no assets. Stores the current token list CID and one encrypted receipt CID per swap
///      transaction. AUDITOR_ROLE is not used here; the backend reads it via hasRole() to decide who
///      may obtain a receipt decryption key.
contract DEXRegistry is IDEXRegistry, AccessControl {
    bytes32 public constant TOKEN_LIST_MANAGER_ROLE = keccak256("TOKEN_LIST_MANAGER_ROLE");
    bytes32 public constant RECEIPT_ISSUER_ROLE = keccak256("RECEIPT_ISSUER_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    /// @inheritdoc IDEXRegistry
    string public tokenListCID;
    /// @inheritdoc IDEXRegistry
    uint256 public tokenListVersion;

    mapping(bytes32 txHash => Receipt) private _receipts;
    mapping(address trader => bytes32[]) private _receiptsOf;

    /// @param admin Receives DEFAULT_ADMIN_ROLE (grants/revokes every role) and TOKEN_LIST_MANAGER_ROLE.
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TOKEN_LIST_MANAGER_ROLE, admin);
    }

    /// @inheritdoc IDEXRegistry
    function setTokenList(string calldata cid) external onlyRole(TOKEN_LIST_MANAGER_ROLE) {
        if (bytes(cid).length == 0) revert EmptyCID();
        tokenListCID = cid;
        uint256 version = ++tokenListVersion;
        emit TokenListUpdated(version, cid);
    }

    /// @inheritdoc IDEXRegistry
    function attachReceipt(bytes32 txHash, address trader, string calldata cid) external onlyRole(RECEIPT_ISSUER_ROLE) {
        if (bytes(cid).length == 0) revert EmptyCID();
        if (bytes(_receipts[txHash].cid).length != 0) revert ReceiptExists();

        _receipts[txHash] = Receipt({cid: cid, trader: trader, timestamp: uint64(block.timestamp)});
        _receiptsOf[trader].push(txHash);
        emit ReceiptAttached(txHash, trader, cid);
    }

    /// @inheritdoc IDEXRegistry
    function getReceipt(bytes32 txHash) external view returns (Receipt memory) {
        return _receipts[txHash];
    }

    /// @inheritdoc IDEXRegistry
    function receiptsOf(address trader) external view returns (bytes32[] memory) {
        return _receiptsOf[trader];
    }
}
