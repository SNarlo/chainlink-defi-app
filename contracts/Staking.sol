// stake: Lock tokens into our smart contracts ✅
// withdraw: Unlock tokens and take tokens out of the contract ✅
// claimReward: users get their reward tokens

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {

    // s_ indicates storage variable
    IERC20 public s_stakingToken;      
    IERC20 public s_rewardsToken;
    
    // someones address -> how much they staked
    mapping(address => uint256) public s_balances;
    
    // a mapping of how much each address has been paid
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    // a mapping of how much reward each address has to claim
    mapping(address => uint256) public s_rewards;

    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;
    uint256 public constant REWARD_RATE = 100;

    modifier updateReward(address _account) {
        // how much reward per token
        // last timestamp
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[_account] = earned(_account);
        s_userRewardPerTokenPaid[_account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 _amount) {
        if(_amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address _stakingToken, address _rewardsToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardsToken = IERC20(_rewardsToken);
    }

    // Based on long it's been during the most recent snapshot.
    function rewardPerToken() public view returns(uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }

        return 
        s_rewardPerTokenStored + 
        (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    function earned(address _account) public view returns (uint256) {
        uint256 currentBalance = s_balances[_account];
        // how much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[_account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[_account];

        uint256 tokensEarned = ((currentBalance * (currentRewardPerToken - amountPaid))/1e18) + pastRewards;
        return tokensEarned;
    }

    // Only allowing one ERC-20 token to be staked.
    // need to keep track of how much each user has staked
    // need to keep track of how much tokens we have in total
    // need to transfer tokens to this contract
    function stake(uint256 _amount) external updateReward(msg.sender) moreThanZero(_amount) {
        s_balances[msg.sender] += _amount;
        s_totalSupply += _amount;
        // emit event
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), _amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) moreThanZero(_amount) {
        s_balances[msg.sender] -= _amount;
        s_totalSupply -= _amount;
        bool success = s_stakingToken.transfer(msg.sender, _amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    // Reward is 100/s distributed to all members of the staking pool.
    // The reward mechanism used here is used by Synthetix protocol.  
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];

        bool success = s_rewardsToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }
}
