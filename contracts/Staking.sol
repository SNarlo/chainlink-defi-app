// stake: Lock tokens into our smart contracts
// withdraw: Unlock tokens and take tokens out of the contract
// claimReward: users get their reward tokens

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();

contract Staking {

    // s_ indicates storage variable
    IERC20 public s_stakingToken;      
    mapping(address => uint256) public s_balances;
    uint256 public s_totalSupply;

    constructor(address _stakingToken) {
        s_stakingToken = IERC20(_stakingToken);
    }

    // Only allowing one ERC-20 token to be staked.
    // need to keep track of how much each user has staked
    // need to keep track of how much tokens we have in total
    // need to transfer tokens to this contract
    function stake(uint256 _amount) public {
        s_balances[msg.sender] += _amount;
        s_totalSupply += _amount;
        // emit event
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), _amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 _amount) external {
        s_balances[msg.sender] -= _amount;
        s_totalSupply -= _amount;
        bool success = s_stakingToken.transfer(msg.sender, _amount);
        if(!success) {
            revert Staking__TransferFailed();
        }
    }
}
