// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ScriptBase} from "./Base.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {AMMRouter} from "../src/AMMRouter.sol";

/// @notice Deploy v1: TokenA, TokenB, AMMPair, AMMRouter. Pair admin and fee setter are wallet #0 for now.
contract Deploy is ScriptBase {
    function run() external {
        uint256 pk = _key(ADMIN);
        address admin = vm.addr(pk);

        vm.startBroadcast(pk);
        TestToken tokenA = new TestToken("TokenA", "TKA", admin);
        TestToken tokenB = new TestToken("TokenB", "TKB", admin);
        // AMMPair does not validate its tokens (SC-10 decision), so the deploy script must.
        require(address(tokenA) != address(0) && address(tokenB) != address(0), "token is zero");
        require(address(tokenA) != address(tokenB), "tokens are identical");
        AMMPair pair = new AMMPair(address(tokenA), address(tokenB), admin);
        AMMRouter router = new AMMRouter(address(pair));
        vm.stopBroadcast();

        string memory k = "addresses";
        vm.serializeAddress(k, "TokenA", address(tokenA));
        vm.serializeAddress(k, "TokenB", address(tokenB));
        vm.serializeAddress(k, "AMMPair", address(pair));
        vm.writeJson(vm.serializeAddress(k, "AMMRouter", address(router)), _addressesPath());
    }
}
