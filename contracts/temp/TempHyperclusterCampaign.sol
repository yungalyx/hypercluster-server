// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "../interface/ICampaign.sol";


contract TempHyperclusterCampaign is ICampaign{

    address public rewardTokenAddress;
    address public rootReferral;
    uint256 public totalSupply;
    uint256 public rewardPercent;
    uint256 public startIn;
    uint256 public endIn;
    string public metadata;
    address public safeAddress;


    uint256 public milestonesReached;
    mapping(address=>uint256)public claimedMilestones;
    mapping(uint256=>uint256) public milestoneRewards;

    mapping(address=>address[2]) public referrals;
    mapping(address=>uint256)public referralTier;

    constructor()
    {
        milestonesReached = 0;

    }


    function initialize(CreateCampaignParams memory params,address _safeAddress) public returns(bool){
        rewardTokenAddress = params.rewardTokenAddress;
        rootReferral = params.rootReferral;
        totalSupply = params.totalSupply;
        startIn = params.startIn;
        endIn = params.endIn;
        metadata = params.metadata;
        safeAddress = _safeAddress;
        rewardPercent = params.rewardPercent;
        referralTier[rootReferral]=1;
        return true;
    }


    event ReferralAdded(address sender, address referral);
    event RewardsClaimed(address claimer,uint amount);
    event MilestoneReached(uint256 milestone);


    function addReferral(address sender)public{
        require(referralTier[msg.sender]==0,"Already in network");
        require(referrals[sender].length<2,"Maximum referrals");
        referrals[sender][referrals[sender].length]=msg.sender;
        referralTier[msg.sender]=referralTier[sender]+1;
        emit ReferralAdded(sender,msg.sender);
    }

    function claimRewards()public{
        uint rewards=_getRewards();
        require(rewards>0,"No rewards");
        require(totalSupply>=rewards,"Not enough rewards");
        milestoneRewards[milestonesReached]-=rewards;
        emit RewardsClaimed(msg.sender,rewards);
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
        uint rewards=totalSupply*rewardPercent/100;
        if(rewards>0) return false;
        milestoneRewards[milestonesReached]=rewards;
        totalSupply-=rewards;
        emit MilestoneReached(milestonesReached);
        return true;
    }

    function _getNextMilestoneRewards() internal view returns(uint256){
        return totalSupply*rewardPercent/100;
    }
}