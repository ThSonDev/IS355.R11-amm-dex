// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

/// @dev Shared by Deploy and Seed: demo wallets and the addresses file (ARCHITECTURE 4.8, SETUP section 6).
abstract contract ScriptBase is Script {
    /// @dev Public Anvil mnemonic; override with the MNEMONIC env var. Wallet #i is derived at m/44'/60'/0'/0/i.
    string internal constant ANVIL_MNEMONIC = "test test test test test test test test test test test junk";

    uint32 internal constant ADMIN = 0;
    uint32 internal constant LP = 1;
    uint32 internal constant TRADER = 2;
    uint32 internal constant COMMUNITY = 3;

    function _key(uint32 wallet) internal view returns (uint256) {
        return vm.deriveKey(vm.envOr("MNEMONIC", ANVIL_MNEMONIC), wallet);
    }

    /// @dev deployments/<chainId>.addresses.json, read by scripts/export-deployments.py. Relative to contracts/.
    function _addressesPath() internal view returns (string memory) {
        return string.concat("../deployments/", vm.toString(block.chainid), ".addresses.json");
    }

    function _loadAddress(string memory label) internal view returns (address) {
        return vm.parseJsonAddress(vm.readFile(_addressesPath()), string.concat(".", label));
    }
}
