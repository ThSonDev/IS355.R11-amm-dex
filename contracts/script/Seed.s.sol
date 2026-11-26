// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ScriptBase} from "./Base.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {AMMRouter} from "../src/AMMRouter.sol";

/// @notice Seed v1: mint to wallets #1-#3, LP adds 10,000/10,000, then the token owner renounces (faucet only afterwards).
contract Seed is ScriptBase {
    uint256 internal constant LP_BALANCE = 100_000 ether;
    uint256 internal constant TRADER_BALANCE = 10_000 ether;
    uint256 internal constant COMMUNITY_BALANCE = 10_000 ether;
    uint256 internal constant POOL_AMOUNT = 10_000 ether;

    function run() external {
        TestToken tokenA = TestToken(_loadAddress("TokenA"));
        TestToken tokenB = TestToken(_loadAddress("TokenB"));
        AMMRouter router = AMMRouter(_loadAddress("AMMRouter"));

        vm.startBroadcast(_key(ADMIN));
        _mint(tokenA, tokenB, vm.addr(_key(LP)), LP_BALANCE);
        _mint(tokenA, tokenB, vm.addr(_key(TRADER)), TRADER_BALANCE);
        _mint(tokenA, tokenB, vm.addr(_key(COMMUNITY)), COMMUNITY_BALANCE);
        tokenA.renounceOwnership();
        tokenB.renounceOwnership();
        vm.stopBroadcast();

        vm.startBroadcast(_key(LP));
        tokenA.approve(address(router), POOL_AMOUNT);
        tokenB.approve(address(router), POOL_AMOUNT);
        router.addLiquidity(
            POOL_AMOUNT, POOL_AMOUNT, POOL_AMOUNT, POOL_AMOUNT, vm.addr(_key(LP)), block.timestamp + 1 hours
        );
        vm.stopBroadcast();
    }

    function _mint(TestToken a, TestToken b, address to, uint256 amount) private {
        a.mint(to, amount);
        b.mint(to, amount);
    }
}
