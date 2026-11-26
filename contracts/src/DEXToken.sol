// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/// @notice "DEX" reward and governance token, ARCHITECTURE 4.4.
/// @dev Fixed supply: 1,000,000 DEX minted once in the constructor, no mint function afterwards.
///      Voting power only counts after the holder delegates (e.g. delegate(self)). The clock is
///      ERC20Votes' default (block.number), so every governance parameter is measured in blocks.
///      Skeleton generated with OpenZeppelin Wizard (ERC20 + Permit + Votes).
contract DEXToken is ERC20, ERC20Permit, ERC20Votes {
    /// @notice Total and fixed supply.
    uint256 public constant TOTAL_SUPPLY = 1_000_000 ether;

    /// @param recipient Receives the whole supply (the deployer, who distributes it at seed time).
    constructor(address recipient) ERC20("DEX Token", "DEX") ERC20Permit("DEX Token") {
        _mint(recipient, TOTAL_SUPPLY);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// @notice Current permit nonce of an owner (shared by ERC20Permit and Nonces).
    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
