// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITestToken} from "./interfaces/ITestToken.sol";

/// @notice Test ERC-20 used as TokenA (TKA) and TokenB (TKB), ARCHITECTURE 4.1.
/// @dev The owner mints liquidity at seed time and then renounces ownership; afterwards
///      the only way to obtain new tokens is the rate-limited faucet.
contract TestToken is ITestToken, ERC20, Ownable {
    /// @notice Amount minted per faucet claim (1000 tokens, 18 decimals).
    uint256 public constant FAUCET_AMOUNT = 1_000 ether;
    /// @notice Minimum time between two faucet claims of the same address.
    uint256 public constant FAUCET_COOLDOWN = 24 hours;

    /// @notice Timestamp of the last faucet claim of each address (0 = never claimed).
    mapping(address => uint256) public lastClaimedAt;

    /// @param name_ Token name, e.g. "TokenA".
    /// @param symbol_ Token symbol, e.g. "TKA".
    /// @param initialOwner Address allowed to mint until ownership is renounced.
    constructor(string memory name_, string memory symbol_, address initialOwner)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {}

    /// @inheritdoc ITestToken
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @inheritdoc ITestToken
    function faucet() external {
        uint256 last = lastClaimedAt[msg.sender];
        if (last != 0) {
            uint256 availableAt = last + FAUCET_COOLDOWN;
            if (block.timestamp < availableAt) revert FaucetCooldown(availableAt);
        }
        lastClaimedAt[msg.sender] = block.timestamp;
        _mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }
}
