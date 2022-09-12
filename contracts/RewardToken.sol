// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    constructor() ERC20("Skux Bux", "SXBX") {
        _mint(msg.sender, 1000000 * 10**18);
    }
} 