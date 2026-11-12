// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Interface of DEXRegistry (RBAC pointers to IPFS resources), ARCHITECTURE 4.7. AccessControl functions are not repeated.
interface IDEXRegistry {
    /// @notice Receipt pointer for a transaction.
    struct Receipt {
        string cid;
        address trader;
        uint64 timestamp;
    }

    /// @notice Token list CID changed.
    event TokenListUpdated(uint256 indexed version, string cid);
    /// @notice Receipt attached to a transaction.
    event ReceiptAttached(bytes32 indexed txHash, address indexed trader, string cid);

    /// @notice A receipt already exists for this txHash.
    error ReceiptExists();
    /// @notice The CID is empty.
    error EmptyCID();

    /// @notice Role allowed to call setTokenList.
    function TOKEN_LIST_MANAGER_ROLE() external view returns (bytes32);
    /// @notice Role allowed to call attachReceipt (backend wallet).
    function RECEIPT_ISSUER_ROLE() external view returns (bytes32);
    /// @notice Role allowed to read all receipts.
    function AUDITOR_ROLE() external view returns (bytes32);

    /// @notice Current token list CID.
    function tokenListCID() external view returns (string memory);
    /// @notice Current token list version.
    function tokenListVersion() external view returns (uint256);
    /// @notice Set the token list CID; TOKEN_LIST_MANAGER_ROLE only.
    function setTokenList(string calldata cid) external;

    /// @notice Attach a receipt CID to a transaction; RECEIPT_ISSUER_ROLE only.
    function attachReceipt(bytes32 txHash, address trader, string calldata cid) external;
    /// @notice Receipt of a transaction.
    function getReceipt(bytes32 txHash) external view returns (Receipt memory);
    /// @notice Transaction hashes of a trader's receipts.
    function receiptsOf(address trader) external view returns (bytes32[] memory);
}
