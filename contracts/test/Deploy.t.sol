// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, Vm} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {Seed} from "../script/Seed.s.sol";
import {Roles} from "../script/Roles.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {DEXToken} from "../src/DEXToken.sol";
import {DEXGovernor} from "../src/DEXGovernor.sol";
import {AMMPair} from "../src/AMMPair.sol";
import {DEXRegistry} from "../src/DEXRegistry.sol";

string constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

/// @dev Environment and output file come from the test, never from the developer's shell or the real file.
contract TestDeploy is Deploy {
    string private file;
    string private mnemonic;
    string private privateKey;

    constructor(string memory file_, string memory mnemonic_, string memory privateKey_) {
        (file, mnemonic, privateKey) = (file_, mnemonic_, privateKey_);
    }

    function _env(string memory name) internal view override returns (string memory) {
        return keccak256(bytes(name)) == keccak256("MNEMONIC") ? mnemonic : privateKey;
    }

    function _addressesPath() internal view override returns (string memory) {
        return file;
    }
}

contract TestSeed is Seed {
    string private file;

    constructor(string memory file_) {
        file = file_;
    }

    function _env(string memory) internal pure override returns (string memory) {
        return "";
    }

    function _addressesPath() internal view override returns (string memory) {
        return file;
    }
}

contract TestRoles is Roles {
    string private file;

    constructor(string memory file_) {
        file = file_;
    }

    function _env(string memory) internal pure override returns (string memory) {
        return "";
    }

    function _addressesPath() internal view override returns (string memory) {
        return file;
    }
}

/// @notice SC-20: Deploy + Seed in-process; every right of ARCHITECTURE 4.8 except StakingRewards (SC-15).
/// @dev setUp runs once, so the addresses file is written by one test run only.
contract DeployTest is Test {
    string constant FILE = "../deployments/test-anvil.addresses.json";

    string json;
    Vm.Log[] recordedLogs;

    address deployer = _wallet(0);
    address lp = _wallet(1);
    address trader = _wallet(2);
    address community = _wallet(3);
    address auditor = _wallet(4);
    address backend = _wallet(5);

    TestToken tokenA;
    TestToken tokenB;
    DEXToken dex;
    TimelockController timelock;
    DEXGovernor governor;
    AMMPair pair;
    DEXRegistry registry;

    /// @dev (contract, role, account) -> still held, replayed from the recorded events.
    mapping(bytes32 => bool) held;
    uint256 heldCount;

    function _wallet(uint32 i) internal pure returns (address) {
        return vm.addr(vm.deriveKey(TEST_MNEMONIC, i));
    }

    function setUp() public {
        vm.chainId(31337);
        vm.recordLogs();
        new TestDeploy(FILE, "", "").run();
        new TestSeed(FILE).run();
        Vm.Log[] memory recorded = vm.getRecordedLogs();
        for (uint256 i = 0; i < recorded.length; i++) {
            recordedLogs.push(recorded[i]);
        }
        new TestRoles(FILE).run();

        json = vm.readFile(FILE);
        vm.removeFile(FILE);
        tokenA = TestToken(_at("TokenA"));
        tokenB = TestToken(_at("TokenB"));
        dex = DEXToken(_at("DEXToken"));
        timelock = TimelockController(payable(_at("Timelock")));
        governor = DEXGovernor(payable(_at("DEXGovernor")));
        pair = AMMPair(_at("AMMPair"));
        registry = DEXRegistry(_at("DEXRegistry"));
    }

    function _at(string memory label) internal view returns (address) {
        return vm.parseJsonAddress(json, string.concat(".", label));
    }

    function test_AddressesFile_And_Wiring() public view {
        assertEq(vm.parseJsonKeys(json, ".").length, 8);
        assertEq(pair.token0(), address(tokenA));
        assertEq(pair.token1(), address(tokenB));
        assertEq(address(governor.token()), address(dex));
        assertEq(governor.timelock(), address(timelock));
    }

    function test_AnvilGovernanceParams() public view {
        assertEq(governor.votingDelay(), 1);
        assertEq(governor.votingPeriod(), 30);
        assertEq(governor.proposalThreshold(), 1_000 ether);
        assertEq(timelock.getMinDelay(), 60);
    }

    function test_Pool_And_TestTokens() public view {
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertEq(r0, 10_000 ether);
        assertEq(r1, 10_000 ether);
        assertEq(tokenA.owner(), address(0));
        assertEq(tokenB.owner(), address(0));
        assertEq(tokenA.balanceOf(lp), 90_000 ether);
        assertEq(tokenB.balanceOf(lp), 90_000 ether);
        assertEq(tokenA.balanceOf(trader), 10_000 ether);
        assertEq(tokenB.balanceOf(community), 10_000 ether);
    }

    function test_DexSplit_And_Delegation() public view {
        assertEq(dex.balanceOf(address(timelock)), 300_000 ether);
        assertEq(dex.balanceOf(lp), 100_000 ether);
        assertEq(dex.balanceOf(trader), 100_000 ether);
        assertEq(dex.balanceOf(community), 100_000 ether);
        assertEq(dex.balanceOf(deployer), 400_000 ether); // staking share, until SC-15
        assertEq(dex.delegates(lp), lp);
        assertEq(dex.delegates(trader), trader);
        assertEq(dex.delegates(community), address(0));
        assertEq(dex.delegates(deployer), address(0));
        assertEq(dex.delegates(address(timelock)), address(0));
    }

    /// @dev The exact set of role holders: anything granted to anyone else makes the count differ.
    function test_RoleTable_ExactHolders() public {
        _replayRoleEvents();

        _assertHolds(address(pair), pair.DEFAULT_ADMIN_ROLE(), address(timelock));
        _assertHolds(address(pair), pair.FEE_SETTER_ROLE(), address(timelock));
        _assertHolds(address(timelock), timelock.PROPOSER_ROLE(), address(governor));
        _assertHolds(address(timelock), timelock.CANCELLER_ROLE(), address(governor));
        _assertHolds(address(timelock), timelock.EXECUTOR_ROLE(), address(0));
        // OZ TimelockController administers itself: role changes need a proposal.
        _assertHolds(address(timelock), timelock.DEFAULT_ADMIN_ROLE(), address(timelock));
        _assertHolds(address(registry), registry.DEFAULT_ADMIN_ROLE(), deployer);
        _assertHolds(address(registry), registry.TOKEN_LIST_MANAGER_ROLE(), deployer);
        _assertHolds(address(registry), registry.RECEIPT_ISSUER_ROLE(), backend);

        assertEq(heldCount, 9);
        assertFalse(registry.hasRole(registry.AUDITOR_ROLE(), auditor));
    }

    function _replayRoleEvents() internal {
        for (uint256 i = 0; i < recordedLogs.length; i++) {
            bytes32 sig = recordedLogs[i].topics[0];
            bool granted = sig == IAccessControl.RoleGranted.selector;
            if (!granted && sig != IAccessControl.RoleRevoked.selector) continue;
            bytes32 key =
                keccak256(abi.encode(recordedLogs[i].emitter, recordedLogs[i].topics[1], recordedLogs[i].topics[2]));
            if (held[key] == granted) continue;
            held[key] = granted;
            heldCount = granted ? heldCount + 1 : heldCount - 1;
        }
    }

    function _assertHolds(address target, bytes32 role, address account) internal view {
        assertTrue(IAccessControl(target).hasRole(role, account));
        assertTrue(held[keccak256(abi.encode(target, role, bytes32(uint256(uint160(account)))))]);
    }
}

/// @notice SC-20: per-chain values and how the deployer and wallet keys are chosen.
contract DeployConfigTest is Test {
    function test_Sepolia_Params_And_PrivateKeyOverride() public {
        string memory file = "../deployments/test-sepolia.addresses.json";
        vm.chainId(11155111);
        new TestDeploy(file, "", "0xa11ce").run();
        string memory json = vm.readFile(file);
        vm.removeFile(file);

        DEXGovernor governor = DEXGovernor(payable(vm.parseJsonAddress(json, ".DEXGovernor")));
        TimelockController timelock = TimelockController(payable(vm.parseJsonAddress(json, ".Timelock")));
        DEXToken dex = DEXToken(vm.parseJsonAddress(json, ".DEXToken"));
        DEXRegistry registry = DEXRegistry(vm.parseJsonAddress(json, ".DEXRegistry"));

        assertEq(governor.votingDelay(), 1);
        assertEq(governor.votingPeriod(), 25);
        assertEq(governor.proposalThreshold(), 1_000 ether);
        assertEq(timelock.getMinDelay(), 120);
        address deployer = vm.addr(0xa11ce);
        assertEq(dex.balanceOf(deployer), 1_000_000 ether);
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), deployer));
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_RevertWhen_PublicMnemonicOutsideAnvil() public {
        vm.chainId(11155111);
        TestDeploy script = new TestDeploy("unused", "", "");
        vm.expectRevert(bytes("set MNEMONIC: the Anvil default is public"));
        script.run();
    }

    function test_RevertWhen_PrivateKeyWithoutPrefix() public {
        vm.chainId(31337);
        TestDeploy script = new TestDeploy("unused", "", "a11ce");
        vm.expectRevert(bytes("private key needs 0x prefix"));
        script.run();
    }

    function test_RevertWhen_UnsupportedChain() public {
        vm.chainId(1);
        TestDeploy script = new TestDeploy("unused", TEST_MNEMONIC, "");
        vm.expectRevert(bytes("unsupported chain"));
        script.run();
    }
}
