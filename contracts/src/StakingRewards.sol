// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

/// @notice Yield farming: stake LP tokens (AMMPair), earn DEX over time pro rata to the stake.
///         Synthetix StakingRewards model, ARCHITECTURE 4.5.
/// @dev Instead of crediting every staker every second, the contract keeps one global accumulator,
///      rewardPerTokenStored = total DEX earned by 1 staked LP since the start (scaled by 1e18).
///      A staker's reward = balance * (rewardPerToken now - rewardPerToken at their last update) + rewards
///      already credited. Both values are refreshed by the updateReward modifier before every state change.
///      There is no admin function to withdraw staked LP or reward tokens.
contract StakingRewards is IStakingRewards, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");

    IERC20 private immutable _stakingToken;
    IERC20 private immutable _rewardToken;

    /// @inheritdoc IStakingRewards
    uint256 public rewardRate;
    /// @inheritdoc IStakingRewards
    uint256 public periodFinish;
    /// @notice Last time rewardPerTokenStored was updated (capped at periodFinish).
    uint256 public lastUpdateTime;
    /// @notice Accumulated DEX per staked LP, scaled by 1e18.
    uint256 public rewardPerTokenStored;

    /// @notice rewardPerToken value at the last update of each account.
    mapping(address account => uint256) public userRewardPerTokenPaid;
    /// @notice Rewards credited to each account but not yet paid out.
    mapping(address account => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address account => uint256) private _balances;

    /// @dev Reward tokens promised by notifyRewardAmount (rewardRate * duration) and not yet paid.
    ///      Keeps a new period from counting unclaimed rewards of earlier periods as available balance.
    uint256 private _rewardsReserved;

    /// @param stakingToken_ LP token being staked (AMMPair).
    /// @param rewardToken_ Reward token (DEXToken).
    /// @param admin Receives DEFAULT_ADMIN_ROLE and REWARD_DISTRIBUTOR_ROLE (the Timelock).
    /// @param distributor Receives REWARD_DISTRIBUTOR_ROLE to fund the first period (the deployer, who renounces later).
    constructor(address stakingToken_, address rewardToken_, address admin, address distributor) {
        _stakingToken = IERC20(stakingToken_);
        _rewardToken = IERC20(rewardToken_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REWARD_DISTRIBUTOR_ROLE, admin);
        _grantRole(REWARD_DISTRIBUTOR_ROLE, distributor);
    }

    /// @dev Bring the global accumulator up to date, then settle `account` (skipped for address(0)).
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // --- views ---

    /// @inheritdoc IStakingRewards
    function stakingToken() external view returns (address) {
        return address(_stakingToken);
    }

    /// @inheritdoc IStakingRewards
    function rewardToken() external view returns (address) {
        return address(_rewardToken);
    }

    /// @inheritdoc IStakingRewards
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IStakingRewards
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Rewards are only accrued up to the end of the current period.
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Accumulated DEX per staked LP right now, scaled by 1e18.
    function rewardPerToken() public view returns (uint256) {
        // Nobody staked: nothing is distributed, and avoid dividing by zero.
        if (_totalSupply == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply;
    }

    /// @inheritdoc IStakingRewards
    function earned(address account) public view returns (uint256) {
        return _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    // --- user actions ---

    /// @inheritdoc IStakingRewards
    function stake(uint256 amount) public nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert ZeroAmount();
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IStakingRewards
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        _withdraw(amount);
    }

    /// @inheritdoc IStakingRewards
    function getReward() public nonReentrant updateReward(msg.sender) {
        _getReward();
    }

    /// @inheritdoc IStakingRewards
    /// @dev Calls the internal versions: calling the public nonReentrant functions from here would revert.
    function exit() external nonReentrant updateReward(msg.sender) {
        _withdraw(_balances[msg.sender]);
        _getReward();
    }

    // --- reward distribution ---

    /// @inheritdoc IStakingRewards
    /// @dev Only after the previous period ended (no top-up mid-period). The contract must already hold
    ///      enough free reward tokens: balance minus rewards promised earlier and not yet paid.
    function notifyRewardAmount(uint256 reward, uint256 duration)
        external
        onlyRole(REWARD_DISTRIBUTOR_ROLE)
        updateReward(address(0))
    {
        if (reward == 0 || duration == 0) revert ZeroAmount();
        if (block.timestamp < periodFinish) revert RewardPeriodActive(periodFinish);

        uint256 rate = reward / duration;
        if (rate == 0) revert ZeroAmount();
        uint256 total = rate * duration;
        if (_rewardToken.balanceOf(address(this)) < _rewardsReserved + total) revert InsufficientRewardBalance();

        _rewardsReserved += total;
        rewardRate = rate;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(reward, duration);
    }

    // --- internal ---

    function _withdraw(uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        if (amount > _balances[msg.sender]) revert InsufficientStake();
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
        _stakingToken.safeTransfer(msg.sender, amount);
    }

    function _getReward() internal {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _rewardsReserved -= reward;
            emit RewardPaid(msg.sender, reward);
            _rewardToken.safeTransfer(msg.sender, reward);
        }
    }
}
