// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract StakeERC20 {
    address public owner;

    address public tokenAddress;

    struct Stakes {
        uint256 amountEarnedFromStaking;
        uint256 amountStaked;
        uint256 beginningOfStakedDate;
        uint256 endOfStakeDate;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    mapping(address => Stakes) balances;

    error NotSufficientAMountToStake();
    error AddressZeroDetected();
    error MinimumStakingDurationIs92();
    error InSufficientAmountToStake();

    function stakeErc20(uint256 _amount, uint256 _duration) payable  public{
        if(msg.sender == address(0)) {
            revert AddressZeroDetected();
        }
    
        if(_amount <= 0) {
            revert NotSufficientAMountToStake();
        }

        uint256 balanceOfToken = IERC20(tokenAddress).balanceOf(msg.sender);
        if (balanceOfToken < _amount) {
            revert InSufficientAmountToStake();
        }

        if(_duration < 92) {
            revert MinimumStakingDurationIs92();
        }

        IERC20(tokenAddress).approve(address(this), _amount);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        balances[msg.sender] = Stakes({
            amountEarnedFromStaking: 0,
            amountStaked: _amount,
            beginningOfStakedDate: block.timestamp,
            endOfStakeDate: block.timestamp + _duration * 1 days
        });
    }
}