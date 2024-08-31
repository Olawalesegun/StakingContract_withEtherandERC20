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

    error AddressZeroDetected();
    error NotSufficientAMountToStake();
    error MinimumStakingDurationIs92();
    error InSufficientAmountToStake();
    error ThisUserDoesNotExist();
    error NoStakeFound();
    error StakeNotMatured();

    event stakingSuccessful(address who, uint256 _duration, uint256 amount);
    event withdrawSuccessful(string status);

    function stakeErc20(uint256 _duration) payable  public{
        if(msg.sender == address(0)) {
            revert AddressZeroDetected();
        }

        uint256 _amount = msg.value;
    
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

        emit stakingSuccessful(msg.sender, _duration, _amount);
    }


    function calcInterest(address staker) private view returns (uint256) {
        Stakes memory userStake = balances[staker];
        uint256 durationStaked;

        if (userStake.amountStaked == 0) {
            revert ThisUserDoesNotExist();
        }

        if (userStake.beginningOfStakedDate > userStake.endOfStakeDate) {
            revert("Invalid staking dates");
        }

        if (block.timestamp > userStake.endOfStakeDate) {
            durationStaked = userStake.endOfStakeDate - userStake.beginningOfStakedDate;
        } else {
            durationStaked = block.timestamp - userStake.beginningOfStakedDate;
        }


        uint256 ratePerDay = 1;
        uint256 interest = (userStake.amountStaked * ratePerDay * durationStaked) / (100 * 1 days);

        return interest;
    }

    function withdraw() public {
        Stakes storage userStake = balances[msg.sender];

        if (userStake.amountStaked == 0) {
            revert NoStakeFound();
        }

        if (block.timestamp < userStake.endOfStakeDate) {
            revert StakeNotMatured();
        }

        uint256 interest = calcInterest(msg.sender);
        uint256 totalAmount = userStake.amountStaked + interest;

        userStake.amountEarnedFromStaking += interest;
        userStake.amountStaked = 0;
        userStake.beginningOfStakedDate = 0;
        userStake.endOfStakeDate = 0;

        IERC20(tokenAddress).transfer(msg.sender, totalAmount);
        emit withdrawSuccessful("Withdraw is Successful");
    }
}