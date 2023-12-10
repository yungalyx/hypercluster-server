// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../interface/ICampaign.sol";

// chainlink Functions 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0


contract Hypercluster is ICampaign {


    uint256 public milestonesReached;
    mapping(address=>uint256)public claimedMilestones;
    mapping(uint256=>uint256) public milestoneRewards;

    mapping(address=>address[]) public referrals;
    mapping(address=>uint256)public referralTier;

    constructor()
    {
        milestonesReached = 0;
    }


    function initialize(CreateCampaignParams memory params) public returns(bool){
        rewardTokenAddress = params.rewardTokenAddress;
        rootReferral = params.rootReferral;
        totalSupply = params.totalSupply;
        milestoneTotalSupply = params.totalSupply;
        startTimestamp = block.timestamp + params.startIn;
        endTimestamp = block.timestamp + params.endIn;
        metadata = params.metadata;
        safeAddress = _safeAddress;
        rewardPercentPerMilestone = params.rewardPercentPerMilestone;
        referralTier[rootReferral]=1;
        return true;
    }


    event ReferralAdded(address sender, address referral);
    event RewardsClaimed(address claimer,uint amount,uint64 destinationSelector);
    event MilestoneReached(uint256 milestone);
    event BotCheckFailed(address botAddress);

    function addReferral(address sender)public{
        require(sender != msg.sender, "Can't refer yourself");
        require(referralTier[msg.sender]==0,"Already in network");
        require(referrals[sender].length < 2, "Maximum referrals"); 
        referrals[sender].push(msg.sender);
        referralTier[msg.sender]=referralTier[sender]+1;
        emit ReferralAdded(sender,msg.sender);
    }

    function getReferred(address sender) public view returns (address[] memory){
      return referrals[sender];
    }

    function isInCampaign(address user) public view returns (bool) {
        return referralTier[user] > 0;
    }

    function claimRewards(uint64 destinationSelector)public{
        uint rewards=_getRewards();
        require(rewards>0,"No rewards");
        require(totalSupply>=rewards,"Not enough rewards");
        milestoneRewards[milestonesReached]-=rewards;
        claimedMilestones[msg.sender]=milestonesReached;
        // TODO: transfer rewards
        emit RewardsClaimed(msg.sender,rewards,destinationSelector);
    }

    function getRewards()public view returns(uint256){
        return _getRewards();
    }

    function _getRewards() internal view returns(uint256){
        uint256 _tier=referralTier[msg.sender];
        uint256 _claimedMilestones=claimedMilestones[msg.sender];

        if(milestonesReached>_claimedMilestones)
        {
            uint256 _rewards=0;
            for(uint i=_claimedMilestones+1;i<=milestonesReached;i++) if(_rewards>0) _rewards+=_tierToRewards(i,_tier);
            return _rewards;
        }else return 0;
       
    }

    function _tierToRewards(uint256 milestone,uint256 tier) internal view returns(uint256){
        uint256 _milestoneReward=milestoneRewards[milestone];
        if(tier<3) return _milestoneReward*(11-tier)/100;
        else if(tier<10) return _milestoneReward*(10-tier)/100;
        else return _milestoneReward*(5**(tier-9))/(10*(tier-8));
    }


    function reachMilestone() public returns(bool){
        milestonesReached++;
        uint rewards=milestoneTotalSupply*rewardPercentPerMilestone/100;
        if(rewards>0) return false;
        milestoneRewards[milestonesReached]=rewards;
        milestoneTotalSupply-=rewards;
        emit MilestoneReached(milestonesReached);
        return true;
    }

    function failBotCheck(address botAddress)public{
        require(referralTier[botAddress]==0,"Already in network");
        emit BotCheckFailed(botAddress);
    }

    function _getNextMilestoneRewards() internal view returns(uint256){
        return milestoneTotalSupply*rewardPercentPerMilestone/100;
    }
}