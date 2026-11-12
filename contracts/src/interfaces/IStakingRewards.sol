// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Interface of StakingRewards (LP staking, Synthetix model), ARCHITECTURE 4.5.
interface IStakingRewards {
    /// @notice LP staked.
    event Staked(address indexed user, uint256 amount);
    /// @notice LP withdrawn.
    event Withdrawn(address indexed user, uint256 amount);
    /// @notice Reward paid out.
    event RewardPaid(address indexed user, uint256 reward);
    /// @notice New reward period started.
    event RewardAdded(uint256 reward, uint256 duration);

    /// @notice Stake/withdraw of 0, or reward or duration of 0.
    error ZeroAmount();
    /// @notice Withdraw is more than the staked amount.
    error InsufficientStake();
    /// @notice notifyRewardAmount called before the current period ended.
    error RewardPeriodActive(uint256 periodFinish);
    /// @notice Contract does not hold enough reward token for rewardRate * duration.
    error InsufficientRewardBalance();

    /// @notice Role allowed to call notifyRewardAmount.
    function REWARD_DISTRIBUTOR_ROLE() external view returns (bytes32);

    /// @notice LP token being staked (AMMPair).
    function stakingToken() external view returns (address);
    /// @notice Reward token (DEX).
    function rewardToken() external view returns (address);

    /// @notice Stake LP (approve first).
    function stake(uint256 amount) external;
    /// @notice Withdraw staked LP.
    function withdraw(uint256 amount) external;
    /// @notice Claim pending reward.
    function getReward() external;
    /// @notice Withdraw everything and claim.
    function exit() external;
    /// @notice Pending reward of an account.
    function earned(address account) external view returns (uint256);
    /// @notice Reward per second.
    function rewardRate() external view returns (uint256);
    /// @notice End time of the current reward period.
    function periodFinish() external view returns (uint256);
    /// @notice Total LP staked.
    function totalSupply() external view returns (uint256);
    /// @notice LP staked by an account.
    function balanceOf(address account) external view returns (uint256);
    /// @notice Start a reward period; REWARD_DISTRIBUTOR_ROLE only.
    function notifyRewardAmount(uint256 reward, uint256 duration) external;
}
