// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ScriptBase} from "./Base.s.sol";
import {TestToken} from "../src/TestToken.sol";

/// @notice Read-only: prints who holds which role, read from the chain, to compare with ARCHITECTURE 4.8.
/// @dev AccessControl cannot list its members, so only the known addresses below are checked.
///      test/Deploy.t.sol checks the exact set from the RoleGranted/RoleRevoked events.
contract Roles is ScriptBase {
    string[9] private names;
    address[9] private who;

    function run() external {
        _loadCandidates();
        console.log("Role holders (checked: deployer, wallets #1-#5, Timelock, Governor, anyone)");
        _owner("TokenA");
        _owner("TokenB");
        _role("AMMPair", "DEFAULT_ADMIN", bytes32(0));
        _role("AMMPair", "FEE_SETTER", keccak256("FEE_SETTER_ROLE"));
        _role("Timelock", "PROPOSER", keccak256("PROPOSER_ROLE"));
        _role("Timelock", "CANCELLER", keccak256("CANCELLER_ROLE"));
        _role("Timelock", "EXECUTOR", keccak256("EXECUTOR_ROLE"));
        _role("Timelock", "DEFAULT_ADMIN", bytes32(0));
        _role("DEXRegistry", "DEFAULT_ADMIN", bytes32(0));
        _role("DEXRegistry", "TOKEN_LIST_MANAGER", keccak256("TOKEN_LIST_MANAGER_ROLE"));
        _role("DEXRegistry", "RECEIPT_ISSUER", keccak256("RECEIPT_ISSUER_ROLE"));
        _role("DEXRegistry", "AUDITOR", keccak256("AUDITOR_ROLE"));
    }

    function _loadCandidates() private {
        names = [
            "Deployer",
            "#1 LP",
            "#2 Trader",
            "#3 Community",
            "#4 Auditor",
            "#5 Backend",
            "Timelock",
            "Governor",
            "anyone(0x0)"
        ];
        who[0] = vm.addr(_deployerKey());
        uint32[5] memory wallets = [LP, TRADER, COMMUNITY, AUDITOR, BACKEND];
        for (uint256 i = 0; i < wallets.length; i++) {
            who[i + 1] = vm.addr(_key(wallets[i]));
        }
        who[6] = _loadAddress("Timelock");
        who[7] = _loadAddress("DEXGovernor");
    }

    function _owner(string memory label) private view {
        address owner = TestToken(_loadAddress(label)).owner();
        console.log("  %s owner: %s", label, owner == address(0) ? "renounced" : vm.toString(owner));
    }

    function _role(string memory label, string memory roleName, bytes32 role) private view {
        IAccessControl target = IAccessControl(_loadAddress(label));
        string memory holders = "";
        for (uint256 i = 0; i < who.length; i++) {
            if (target.hasRole(role, who[i])) holders = string.concat(holders, " [", names[i], "]");
        }
        console.log("  %s %s:%s", label, roleName, bytes(holders).length == 0 ? " none" : holders);
    }
}
