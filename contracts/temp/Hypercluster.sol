// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

import "../interface/ICampaign.sol";

contract Hypercluster is ICampaign, FunctionsClient, ConfirmedOwner, AutomationCompatibleInterface {

    string public name;
    string public metadata;
    address public creator;

    uint256 public milestonesReached;
    mapping(address=>uint256)public claimedMilestones;
    mapping(uint256=>uint256) public milestoneRewards;

    mapping(address=>address[]) public referrals;
    mapping(address=>uint256)public referralTier;

    address public rewardTokenAddress;
    address public rootReferral;
    uint256 public totalSupply;
    uint256 public milestoneTotalSupply;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public rewardPercentPerMilestone;
    uint256 public increaseRate;
    uint256 public thresholdPrice;

    uint256 public customLogicUpkeepId;

    AggregatorV3Interface public dataFeed;
    LinkTokenInterface public constant linkToken=LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    address public constant functionsRouter=0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 public constant donId=0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint64 public constant sourceChainSelector=16015286601757825753;
    address public constant ccipRouter=0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;

    constructor()  FunctionsClient(functionsRouter) ConfirmedOwner(msg.sender) {}

    function initialize(CreateCampaignParams memory params,uint256 _upKeepId,address _creator) public returns(bool){
        name=params.name;
        metadata = params.metadata;
        rewardTokenAddress = params.rewardTokenAddress;
        rootReferral = params.rootReferral;
        creator=_creator;
        totalSupply = params.totalSupply;
        milestoneTotalSupply = params.totalSupply;
        startTimestamp = block.timestamp + params.startIn;
        endTimestamp = block.timestamp + params.endIn;
        increaseRate=params.increaseRate;
        rewardPercentPerMilestone = params.rewardPercentPerMilestone;
        
        referralTier[rootReferral]=1;
        customLogicUpkeepId=_upKeepId;
        dataFeed=AggregatorV3Interface(params.dataFeedAddress);
        
        thresholdPrice = (uint256(_getPrice()) * increaseRate) / 1e4;
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


    function claimRewards(uint64 destinationSelector)public{
        uint rewards=_getRewards();
        require(rewards>0,"No rewards");
        require(totalSupply>=rewards,"Not enough rewards");
        milestoneRewards[milestonesReached]-=rewards;
        claimedMilestones[msg.sender]=milestonesReached;
        // TODO: transfer rewards
        emit RewardsClaimed(msg.sender,rewards,destinationSelector);
    }

    // NOT FOR PRODUCTION. TESTING FUNCTION FOR THIS HACKATHON. SHOULD BE CALLED BY UPKEEP IN PRODUCTION
    function reachMilestone() external returns(bool){
        return _reachMilestone();
    }

    function _reachMilestone() internal returns(bool){
        milestonesReached++;
        uint rewards=milestoneTotalSupply*rewardPercentPerMilestone/100;
        if(rewards==0) return false;
        milestoneRewards[milestonesReached]=rewards;
        milestoneTotalSupply-=rewards;
        emit MilestoneReached(milestonesReached);
        return true;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        
    }

    function _getPrice() internal view returns (int) {
        (,int answer,,,) = dataFeed.latestRoundData();
        return answer;
    } 


    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded,bytes memory )
    {
        uint256 currentPrice=uint256(_getPrice());
        upkeepNeeded = currentPrice >= thresholdPrice;
    }

    function performUpkeep(bytes calldata ) external override {
       _reachMilestone();
    }

    function _failBotCheck(address _botAddress) internal {
        require(referralTier[_botAddress]==0,"Already in network");
        emit BotCheckFailed(_botAddress);
    }


    function getReferred(address sender) public view returns (address[] memory){
      return referrals[sender];
    }

    function isInCampaign(address user) public view returns (bool) {
        return referralTier[user] > 0;
    }

    function getRewards()external view returns(uint256){
        return _getRewards();
    }

    function _getRewards() internal view returns(uint256){
        uint256 _tier=referralTier[msg.sender];
        uint256 _claimedMilestones=claimedMilestones[msg.sender];
        uint256 _rewards=0;
        if(milestonesReached>_claimedMilestones) for(uint i=_claimedMilestones+1;i<=milestonesReached;i++) if(_rewards>0) _rewards+=_tierToRewards(i,_tier);
        return _rewards;
    }

    function _tierToRewards(uint256 milestone,uint256 tier) internal view returns(uint256){
        uint256 _milestoneReward=milestoneRewards[milestone];
        if(tier<3) return _milestoneReward*(11-tier)/100;
        else if(tier<10) return _milestoneReward*(10-tier)/100;
        else return _milestoneReward*(5**(tier-9))/(10*(tier-8));
    }

    function _getNextMilestoneRewards() internal view returns(uint256){
        return milestoneTotalSupply*rewardPercentPerMilestone/100;
    }
}