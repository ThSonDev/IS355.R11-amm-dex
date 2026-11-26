// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {Seed} from "../script/Seed.s.sol";
import {TestToken} from "../src/TestToken.sol";
import {AMMPair} from "../src/AMMPair.sol";

contract DeployTest is Test {
    string constant FILE = "../deployments/424242.addresses.json";

    function setUp() public {
        vm.chainId(424242); // a throwaway chain id, so the real 31337 addresses file is never touched
    }

    function test_deploy_then_seed() public {
        new Deploy().run();

        string memory json = vm.readFile(FILE);
        string[4] memory labels = ["TokenA", "TokenB", "AMMPair", "AMMRouter"];
        for (uint256 i = 0; i < labels.length; i++) {
            assertTrue(vm.parseJsonAddress(json, string.concat(".", labels[i])).code.length > 0, labels[i]);
        }
        assertEq(vm.parseJsonKeys(json, ".").length, 4);

        new Seed().run();

        TestToken a = TestToken(vm.parseJsonAddress(json, ".TokenA"));
        TestToken b = TestToken(vm.parseJsonAddress(json, ".TokenB"));
        AMMPair pair = AMMPair(vm.parseJsonAddress(json, ".AMMPair"));
        (uint256 r0, uint256 r1) = pair.getReserves();
        assertEq(r0, 10_000 ether);
        assertEq(r1, 10_000 ether);
        assertEq(a.owner(), address(0));
        assertEq(b.owner(), address(0));
        assertEq(pair.token0(), address(a));
        assertEq(pair.token1(), address(b));

        vm.removeFile(FILE);
    }
}
