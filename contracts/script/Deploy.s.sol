// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ScriptBase} from "./Base.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {DEXToken} from "../src/DEXToken.sol";
import {DEXGovernor} from "../src/DEXGovernor.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {AMMRouter} from "../src/AMMRouter.sol";
import {DEXRegistry} from "../src/DEXRegistry.sol";
import {StakingRewards} from "../src/StakingRewards.sol";

/// @notice Deploys every contract in the SC-20 order and configures the Timelock (ARCHITECTURE 4.6, 4.8).
/// @dev The whole DEX supply goes to the deployer; Seed distributes it.
contract Deploy is ScriptBase {
    uint256 internal constant PROPOSAL_THRESHOLD = 1_000 ether;
    string private constant JSON = "addresses";

    struct GovParams {
        uint48 votingDelay;
        uint32 votingPeriod;
        uint256 minDelay;
    }

    /// @dev ARCHITECTURE 4.6. Delays are in blocks, minDelay in seconds.
    function _govParams() internal view returns (GovParams memory) {
        if (block.chainid == ANVIL) return GovParams({votingDelay: 1, votingPeriod: 30, minDelay: 60});
        require(block.chainid == SEPOLIA, "unsupported chain");
        return GovParams({votingDelay: 1, votingPeriod: 25, minDelay: 120});
    }

    function run() external {
        GovParams memory p = _govParams();
        uint256 pk = _deployerKey();
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);
        TestToken tokenA = new TestToken("TokenA", "TKA", deployer);
        TestToken tokenB = new TestToken("TokenB", "TKB", deployer);
        DEXToken dex = new DEXToken(deployer);

        TimelockController timelock = new TimelockController(p.minDelay, new address[](0), new address[](0), deployer);
        DEXGovernor governor = new DEXGovernor(dex, timelock, p.votingDelay, p.votingPeriod, PROPOSAL_THRESHOLD);
        _configureTimelock(timelock, address(governor), deployer);

        // AMMPair does not validate its tokens (SC-10 decision), so the deploy script must.
        require(address(tokenA) != address(0) && address(tokenB) != address(0), "token is zero");
        require(address(tokenA) != address(tokenB), "tokens are identical");
        AMMPair pair = new AMMPair(address(tokenA), address(tokenB), address(timelock));
        AMMRouter router = new AMMRouter(address(pair));

        // Timelock is admin and distributor; the deployer is distributor only until Seed funds the first period.
        StakingRewards staking = new StakingRewards(address(pair), address(dex), address(timelock), deployer);
        DEXRegistry registry = new DEXRegistry(deployer);
        vm.stopBroadcast();

        vm.serializeAddress(JSON, "TokenA", address(tokenA));
        vm.serializeAddress(JSON, "TokenB", address(tokenB));
        vm.serializeAddress(JSON, "DEXToken", address(dex));
        vm.serializeAddress(JSON, "Timelock", address(timelock));
        vm.serializeAddress(JSON, "DEXGovernor", address(governor));
        vm.serializeAddress(JSON, "AMMPair", address(pair));
        vm.serializeAddress(JSON, "AMMRouter", address(router));
        vm.serializeAddress(JSON, "StakingRewards", address(staking));
        vm.writeJson(vm.serializeAddress(JSON, "DEXRegistry", address(registry)), _addressesPath());
    }

    /// @dev Governor proposes and cancels, anyone executes, then the deployer gives up the admin role.
    function _configureTimelock(TimelockController timelock, address governor, address deployer) private {
        timelock.grantRole(timelock.PROPOSER_ROLE(), governor);
        timelock.grantRole(timelock.CANCELLER_ROLE(), governor);
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(0));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), deployer);
    }
}
