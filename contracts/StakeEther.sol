// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

contract StakeEther {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    struct Stakes {
        uint256 amountEarnedFromStaking;
        uint256 amountStaked;
        uint256 beginningOfStakedDate;
        uint256 endOfStakeDate;
    }

    // mapping(address => uint256) balance;
    mapping(address => Stakes) usersStakes;

    error AddressZeroNotAccepted();
    error ValuesLessThan1EtherIsNotAccepted();
    error MinimumStakingLengthIs92Days();
    error ThisUserDoesNotExist();
    error NoStakeFoundForThisUser();
    error YouCantWithdrawTillYouMeetThreshold();
    error YouCantStakeTwiceHere();
    error ThisIsNotAuthorized();
    error YouCantWithdrawThisAmount();
    

    function stake(uint durationOfStake) payable external {
         if(msg.sender == address(0)){
            revert AddressZeroNotAccepted();
        }

        if(usersStakes[msg.sender].amountStaked != 0) {
            revert YouCantStakeTwiceHere();
        }
        
        if (durationOfStake < 92) {
            revert MinimumStakingLengthIs92Days();
        }

        if(msg.value < 1 ether ) {
            revert ValuesLessThan1EtherIsNotAccepted();
        }

        // (bool status, bytes memory data) = address(this).call{value: msg.value}("");

        usersStakes[msg.sender].amountStaked += msg.value;
        usersStakes[msg.sender].beginningOfStakedDate = block.timestamp;
        usersStakes[msg.sender].endOfStakeDate = block.timestamp + durationOfStake;

    }

    function calcInterest(address staker, uint256 amountDeposited, uint256 numberOfDaysSetForStaking) private view returns(uint256){
        Stakes storage userStake = usersStakes[staker];
        
        if(userStake.amountStaked == 0) {
            revert ThisUserDoesNotExist();
        }

        if (msg.sender != owner && msg.sender != staker) {
            revert ThisIsNotAuthorized();
        }
        uint SCALING_FACTOR = 10**2;
        uint256 rate = 1;
        uint256 timeInSeconds = numberOfDaysSetForStaking * 24 * 60 * 60;
        return (amountDeposited * rate * timeInSeconds) / (SCALING_FACTOR * 100);

    }

     function withdrawReward() internal {
        Stakes storage userStake = usersStakes[msg.sender];
        if(userStake.amountStaked <= 0) {
            revert NoStakeFoundForThisUser();
        }
        // uint256 checkIfEligibleToWithdraw = block.timestamp - userStake.endOfStakeDate;
        
        if(block.timestamp < userStake.endOfStakeDate){
            revert YouCantWithdrawTillYouMeetThreshold();

        }
        uint256 expectedROI = calcInterest(msg.sender, userStake.amountStaked, userStake.endOfStakeDate);
        uint256 stakedEarning = userStake.amountStaked + expectedROI;
        
        if(msg.value > stakedEarning) {
            revert YouCantWithdrawThisAmount();
        }
        // uint256 stakeDuration = (userStake.endOfStakeDate - userStake.beginningOfStakedDate) / 1 days;
        // uint256 interest = calcInterest(msg.sender, userStake.amountStaked, stakeDuration);
        // uint256 totalAmount = userStake.amountStaked + interest;
        userStake.amountEarnedFromStaking += stakedEarning;
        

        payable(msg.sender).transfer(stakedEarning);
    }

}