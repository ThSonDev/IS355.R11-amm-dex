// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Interface of TestToken (TKA/TKB), ARCHITECTURE 4.1. ERC20 and Ownable functions are not repeated.
interface ITestToken {
    /// @notice Emitted when a user claims from the faucet.
    event FaucetClaimed(address indexed user, uint256 amount);

    /// @notice Faucet claimed again before the 24h cooldown ended.
    error FaucetCooldown(uint256 availableAt);

    /// @notice Mint tokens; owner only, used at seed time before ownership is renounced.
    function mint(address to, uint256 amount) external;

    /// @notice Claim 1000 tokens, once per address per 24h.
    function faucet() external;
}
