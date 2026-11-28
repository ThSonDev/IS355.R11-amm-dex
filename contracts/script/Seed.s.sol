// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ScriptBase} from "./Base.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {DEXToken} from "../src/DEXToken.sol";
import {AMMRouter} from "../src/AMMRouter.sol";
import {DEXRegistry} from "../src/DEXRegistry.sol";
import {StakingRewards} from "../src/StakingRewards.sol";

/// @notice Demo state: test token balances, DEX split (ARCHITECTURE 4.4), first reward period, delegation, Registry roles,
///         token ownership renounced (faucet only afterwards) and a 10,000/10,000 pool.
contract Seed is ScriptBase {
    uint256 internal constant LP_BALANCE = 100_000 ether;
    uint256 internal constant TRADER_BALANCE = 10_000 ether;
    uint256 internal constant COMMUNITY_BALANCE = 10_000 ether;
    uint256 internal constant POOL_AMOUNT = 10_000 ether;
    uint256 internal constant DEX_STAKING = 400_000 ether; // 40%
    uint256 internal constant REWARD_DURATION = 30 days;
    uint256 internal constant DEX_TREASURY = 300_000 ether; // 30%
    uint256 internal constant DEX_PER_WALLET = 100_000 ether; // 10% each

    function run() external {
        vm.startBroadcast(_deployerKey());
        _seedTestTokens();
        _distributeDex();
        _fundStaking();
        // Registry admin (the deployer) already has TOKEN_LIST_MANAGER from the constructor.
        DEXRegistry registry = DEXRegistry(_loadAddress("DEXRegistry"));
        registry.grantRole(registry.RECEIPT_ISSUER_ROLE(), vm.addr(_key(BACKEND)));
        vm.stopBroadcast();

        // Community is left undelegated on purpose: the demo shows that step.
        _delegateSelf(LP);
        _delegateSelf(TRADER);
        _addLiquidity();
    }

    function _seedTestTokens() private {
        TestToken a = TestToken(_loadAddress("TokenA"));
        TestToken b = TestToken(_loadAddress("TokenB"));
        _mint(a, b, vm.addr(_key(LP)), LP_BALANCE);
        _mint(a, b, vm.addr(_key(TRADER)), TRADER_BALANCE);
        _mint(a, b, vm.addr(_key(COMMUNITY)), COMMUNITY_BALANCE);
        a.renounceOwnership();
        b.renounceOwnership();
    }

    function _distributeDex() private {
        DEXToken dex = DEXToken(_loadAddress("DEXToken"));
        dex.transfer(_loadAddress("Timelock"), DEX_TREASURY);
        dex.transfer(vm.addr(_key(LP)), DEX_PER_WALLET);
        dex.transfer(vm.addr(_key(TRADER)), DEX_PER_WALLET);
        dex.transfer(vm.addr(_key(COMMUNITY)), DEX_PER_WALLET);
    }

    /// @dev Starts the first reward period, then the deployer gives up REWARD_DISTRIBUTOR (the Timelock keeps it).
    function _fundStaking() private {
        StakingRewards staking = StakingRewards(_loadAddress("StakingRewards"));
        DEXToken(_loadAddress("DEXToken")).transfer(address(staking), DEX_STAKING);
        staking.notifyRewardAmount(DEX_STAKING, REWARD_DURATION);
        staking.renounceRole(staking.REWARD_DISTRIBUTOR_ROLE(), vm.addr(_deployerKey()));
    }

    function _delegateSelf(uint32 wallet) private {
        uint256 pk = _key(wallet);
        DEXToken dex = DEXToken(_loadAddress("DEXToken"));
        vm.broadcast(pk);
        dex.delegate(vm.addr(pk));
    }

    function _addLiquidity() private {
        AMMRouter router = AMMRouter(_loadAddress("AMMRouter"));
        address lp = vm.addr(_key(LP));
        vm.startBroadcast(_key(LP));
        TestToken(_loadAddress("TokenA")).approve(address(router), POOL_AMOUNT);
        TestToken(_loadAddress("TokenB")).approve(address(router), POOL_AMOUNT);
        router.addLiquidity(POOL_AMOUNT, POOL_AMOUNT, POOL_AMOUNT, POOL_AMOUNT, lp, block.timestamp + 1 hours);
        vm.stopBroadcast();
    }

    function _mint(TestToken a, TestToken b, address to, uint256 amount) private {
        a.mint(to, amount);
        b.mint(to, amount);
    }
}
