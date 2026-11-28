// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

/// @dev Shared by the scripts: demo wallets and the addresses file (ARCHITECTURE 4.8, SETUP section 6).
abstract contract ScriptBase is Script {
    /// @dev Public Anvil mnemonic, the default on the local chain only. Wallet #i is at m/44'/60'/0'/0/i.
    string internal constant ANVIL_MNEMONIC = "test test test test test test test test test test test junk";
    uint256 internal constant ANVIL = 31337;
    uint256 internal constant SEPOLIA = 11155111;

    uint32 internal constant ADMIN = 0;
    uint32 internal constant LP = 1;
    uint32 internal constant TRADER = 2;
    uint32 internal constant COMMUNITY = 3;
    uint32 internal constant AUDITOR = 4;
    uint32 internal constant BACKEND = 5;

    /// @dev Virtual so tests do not depend on the developer's environment.
    function _env(string memory name) internal view virtual returns (string memory) {
        return vm.envOr(name, string(""));
    }

    /// @dev MNEMONIC env var. Anyone can spend from the Anvil mnemonic, so other chains must set their own.
    function _key(uint32 wallet) internal view returns (uint256) {
        string memory mnemonic = _env("MNEMONIC");
        if (bytes(mnemonic).length == 0) {
            require(block.chainid == ANVIL, "set MNEMONIC: the Anvil default is public");
            mnemonic = ANVIL_MNEMONIC;
        }
        return vm.deriveKey(mnemonic, wallet);
    }

    /// @dev Wallet #0, unless DEPLOYER_PRIVATE_KEY (SETUP section 4) is set.
    function _deployerKey() internal view returns (uint256) {
        string memory key = _env("DEPLOYER_PRIVATE_KEY");
        if (bytes(key).length == 0) return _key(ADMIN);
        // Checked before parsing: the cheatcode's own parse error would echo the value.
        require(bytes(key).length > 2 && bytes(key)[0] == "0" && bytes(key)[1] == "x", "private key needs 0x prefix");
        return vm.parseUint(key);
    }

    /// @dev deployments/<chainId>.addresses.json, read by scripts/export-deployments.py. Relative to contracts/.
    function _addressesPath() internal view virtual returns (string memory) {
        return string.concat("../deployments/", vm.toString(block.chainid), ".addresses.json");
    }

    function _loadAddress(string memory label) internal view returns (address) {
        return vm.parseJsonAddress(vm.readFile(_addressesPath()), string.concat(".", label));
    }
}
