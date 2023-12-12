// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

// Chailink imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

// Openzeppelin imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Structs and interfaces
import './StructLib.sol';
import "./interface/ILogAutomation.sol";

/// @title Hypercluster - The Web3 Automated Referral System
/// @author @gabrielantonyxaviour and @yungalyx
/// @notice Submitted for Chailink Constellation 2023 Hackathon
/// @dev Powered by Chainlink Functions, Chainlink CCIP, Chainlink Automation and Chainlink Price Feeds

contract Hypercluster is  FunctionsClient, ConfirmedOwner, AutomationCompatibleInterface {
    // Libraries
    using Strings for uint256;
    using FunctionsRequest for FunctionsRequest.Request;

    // structs
    struct Referral{
        address receiver;
        string referralCode;
    }
    
    // Campaign metadata
    string public name;
    string public metadata;
    address public creator;

    // Milestone public variables
    uint256 public milestonesReached;
    mapping(address=>uint256)public claimedMilestones;
    mapping(uint256=>uint256) public milestoneRewards;

    // referral public variables
    mapping(address=>address[]) public referrals;
    mapping(address=>uint256)public referralTier;
    mapping(string=>uint256) public referralCodeToReferredCount;
    mapping(bytes32=>Referral) public requestIdsToReferrals;

    // Campaign specific public variables
    IERC20 public rewardToken;
    address public rootReferral;
    uint256 public totalSupply;
    uint256 public milestoneTotalSupply;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public rewardPercentPerMilestone;
    uint256 public increaseRate;
    uint256 public thresholdPrice;
    uint256 public initialPrice;

    // Chainlink public variables
    AggregatorV3Interface public dataFeed;
    LinkTokenInterface public  linkToken;
    IRouterClient public  ccipRouter;
    address public  functionsRouter;
    bytes32 public  donId;
    uint64 public  sourceChainSelector;
    uint64 public  subscriptionId;
    uint32 public functionsCallbackGasLimit;
    string public validationSourceCode;

    constructor(CreateCampaignParams memory params,address _creator,string memory _validationSourceCode,LinkTokenInterface _linkToken,IRouterClient _ccipRouter,address _functionsRouter, bytes32 _donId,uint64 _sourceChainSelector,uint64 _subscriptionId)  FunctionsClient(_functionsRouter) ConfirmedOwner(msg.sender) {
        validationSourceCode=_validationSourceCode;
        linkToken=_linkToken;
        ccipRouter=_ccipRouter;
        functionsRouter=_functionsRouter;
        donId=_donId;
        sourceChainSelector=_sourceChainSelector;
        subscriptionId=_subscriptionId;
        _initialize(params,_creator);
    }

    // Events
    event ReferralAdded(address sender, address referral);
    event RewardsClaimed(address claimer,uint amount,uint64 destinationSelector);
    event MilestoneReached(uint256 milestone);
    event BotCheckFailed(address botAddress);
    event CannotReferYourself();
    event FunctionsError(string err);
    event FunctionsRequestFulfilled(
        bytes32  requestId,
        bytes  data,
        bytes  error
    );

    /// @notice Called on initialization of the campaign
    /// @dev Calculates the threshold price to reach the first milestone of the campaign
    /// @param params campaign specific parameters
    /// @param _creator The creator of the campaign
    /// @return success returns true if the campaign is successfully initialized
    function _initialize(CreateCampaignParams memory params,address _creator) internal returns(bool){
        name=params.name;
        metadata = params.metadata;
        rewardToken = IERC20(params.rewardTokenAddress);
        rootReferral = params.rootReferral;
        creator=_creator;
        totalSupply = params.totalSupply;
        milestoneTotalSupply = params.totalSupply;
        startTimestamp = block.timestamp + params.startIn;
        endTimestamp = block.timestamp + params.endIn;
        increaseRate=params.increaseRate;
        rewardPercentPerMilestone = params.rewardPercentPerMilestone;
        
        referralTier[rootReferral]=1;
        dataFeed=AggregatorV3Interface(params.dataFeedAddress);
        
        uint256 currentPrice=uint256(_getPrice());
        thresholdPrice = currentPrice+((currentPrice * increaseRate) / 1e4);
        return true;
    }

    /// @notice Called by the referral with a referral code to join the campaign
    /// @dev With help of Chainlink functions, the caller is verified for anti-bot and the referral code is validated
    /// @param args Pass the referral code as the first argument
    /// @param slotId The slotId of the DON encrypted secrets
    /// @param version The version of the DON encrypted secrets
    /// @param encryptedSecretsUrls The encrypted secrets urls of the Chainlink Functions (LEAVE EMPTY)
    /// @param bytesArgs The bytesArgs of the Chainlink Functions (LEAVE EMPTY)
    function addReferral(string[] memory args, uint8 slotId,uint64 version, bytes memory encryptedSecretsUrls,bytes[] memory bytesArgs)public{
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(validationSourceCode);

        require(referralTier[msg.sender]==0,"Already in network");
        require(referralCodeToReferredCount[args[0]]<2,"Maximum referrals");
        referralCodeToReferredCount[args[0]]+=1;
        
        args[1]=Strings.toHexString(uint256(uint160(msg.sender)), 20);
        if(encryptedSecretsUrls.length>0) req.addSecretsReference(encryptedSecretsUrls);
        else if (version > 0)
            req.addDONHostedSecrets(
                slotId,
                version
            );

        if (args.length > 0) req.setArgs(args);
        if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
        req.setArgs(args);
        requestIdsToReferrals[_sendRequest(req.encodeCBOR(), subscriptionId, functionsCallbackGasLimit, donId)] = Referral(msg.sender,args[0]);  
        referralTier[msg.sender]=referralTier[rootReferral]+1;
        
    }


    /// @notice Callback function of the Chainlink Functions request
    /// @dev Emits the FunctionsRequestFulfilled event which is listened by the Log Trigger Automation which updates the referral network
    /// @param requestId The requestId of the Chainlink Functions request
    /// @param response The response of the Chainlink Functions request
    /// @param err The error returned by the Chainlink Functions request    
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        emit FunctionsRequestFulfilled(requestId, response, err);
    }

    /// @notice Called by the users in the network to claim their rewards
    /// @dev The rewards are calculated based on the milestones reached and the tier of the user. With the help of Chainlink CCIP, the rewards can be claimed on any chain.
    /// @param destinationAddress The address of the user to receive the rewards
    /// @param destinationSelector The chain selector of the destination chain where the user would like to claim the rewards
    function claimRewards(address destinationAddress,uint64 destinationSelector)public{
        uint rewards=_getRewards();
        require(rewards>0,"No rewards");
        require(rewardToken.balanceOf(address(this))>=rewards,"Not enough rewards");
        milestoneRewards[milestonesReached]-=rewards;
        claimedMilestones[msg.sender]=milestonesReached;

        if(destinationSelector==sourceChainSelector) rewardToken.transfer(destinationAddress,rewards);
        else{
            _transferCrosschain(destinationAddress, destinationSelector, rewards);
        }
        emit RewardsClaimed(msg.sender,rewards,destinationSelector);
    }


    /// @notice Internal function which is called on claimRewards
    /// @dev With the help of Chainlink CCIP, the rewards are transferred to the destination chain
    /// @param destinationAddress The address of the user to receive the rewards
    /// @param _destinationChainSelector The chain selector of the destination chain where the user would like to claim the rewards
    /// @param rewards The amount of rewards to be transferred
    /// @return messageId The messageId of the Chainlink CCIP request
    function _transferCrosschain(address destinationAddress,uint64 _destinationChainSelector,uint256 rewards) internal returns(bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                destinationAddress,
                address(rewardToken),
                rewards,
                address(linkToken)
            );

            uint256 fees = ccipRouter.getFee(
                _destinationChainSelector,
                evm2AnyMessage
            );

            require(fees>linkToken.balanceOf(address(this)),"Not enough LINK to claim crosschain");

            linkToken.approve(address(ccipRouter),fees);
            rewardToken.approve(address(ccipRouter),rewards);

            messageId = ccipRouter.ccipSend(
                _destinationChainSelector,
                evm2AnyMessage
            );

            return messageId;
    }

    /// @notice Internal function to build the Chainlink CCIP message
    /// @dev The Chainlink CCIP message is built with the help of Chainlink CCIP library
    /// @param _receiver The address of the user to receive the rewards
    /// @param _token The address of the token to be transferred
    /// @param _amount The amount of tokens to be transferred
    /// @param _feeTokenAddress The address of the token to be used as fee
    /// @return Client EVM2AnyMessage The Chainlink CCIP message
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), 
                data: "", 
                tokenAmounts: tokenAmounts, 
                extraArgs: "",
                feeToken: _feeTokenAddress
            });
    }

    // NOT FOR PRODUCTION. TESTING FUNCTION FOR THIS HACKATHON. IN PRODUCTION, IT WILL BE CALLED ONLY BY `performUpkeep` function
    function reachMilestone() external returns(bool){
        return _reachMilestone();
    }

    /// @notice Internal function which is called by the Chainlink Custom Logic Automation on reaching the threshold price for the milestone
    /// @dev The milestone is updated and the rewards are updated to be claimed for the milestone
    /// @return success returns true if the milestone is successfully updated
    function _reachMilestone() internal returns(bool){
        milestonesReached++;
        uint rewards=milestoneTotalSupply*rewardPercentPerMilestone/100;
        if(rewards==0) return false;
        milestoneRewards[milestonesReached]=rewards;
        milestoneTotalSupply-=rewards;
        emit MilestoneReached(milestonesReached);
        return true;
    }

    /// @notice Internal function which returns the current price of the token with the help of Chainlink Price Feeds
    function _getPrice() internal view returns (int) {
        (,int answer,,,) = dataFeed.latestRoundData();
        return answer;
    } 

    /// @notice Called by the Chainlink Log Trigger Automation when the FunctionsRequestFulfilled Event is emitted
    /// @dev The Chainlink Log Trigger Automation toggles upkeep needed on receiving the event
    /// @param log The Chainlink Log Trigger Automation log Struct
    /// @param checkData The checkData of the Chainlink Log Trigger Automation
    /// @return upkeepNeeded returns true if the event is received
    /// @return performData The performData of the Chainlink Log Trigger Automation
    function checkLog(
        ILogAutomation.Log calldata log,
        bytes memory checkData
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        performData=log.data;
    }
    
    /// @notice Called by the Chainlink Custom Logic Automation to check if the threshold price is reached
    /// @dev The threshold price is checked and if reached upkeep is toggled to perform the milestone update
    /// @return upkeepNeeded returns true if the threshold price is reached
    /// @return performData The performData of the Chainlink Log Trigger Automation
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded,bytes memory performData)
    {
        uint256 currentPrice=uint256(_getPrice());
        upkeepNeeded = currentPrice >= thresholdPrice;
        performData="";
    }

    /// @notice Called by the Chainlink Automation to perform the automation
    /// @dev If performData is present, then it is decoded to get the requestId, response and err of the Chainlink Functions request which is used to update the referral network
    /// @dev If performData is not present, then the threshold price is updated and the milestone is reached
    /// @param performData The performData of the Chainlink Automation
    function performUpkeep(bytes calldata performData) external override {
        if(performData.length==0)
        {
            uint256 currentPrice=uint256(_getPrice());
            thresholdPrice=currentPrice*((currentPrice * increaseRate) / 1e4);
           _reachMilestone();
        }
       else{
    (bytes32 requestId,bytes memory response,bytes memory err) = abi.decode(performData,(bytes32,bytes,bytes));
      Referral memory referral=requestIdsToReferrals[requestId];

        if(response.length>0)
        {
            string memory referrerAddressString=string(response);
            address referrerAddress=address(bytes20(bytes(referrerAddressString)));
            if(referrerAddress==referral.receiver)
            {
                referralCodeToReferredCount[referral.referralCode]-=1;
                emit CannotReferYourself();
            }else{
                referrals[referrerAddress].push(referral.receiver);
                referralTier[referral.receiver]=referralTier[referrerAddress]+1;
                emit ReferralAdded(referrerAddress,referral.receiver);
            }
        }else{
            string memory errString=string(err);
            if(keccak256(err)==keccak256(bytes("BOT"))) emit BotCheckFailed(requestIdsToReferrals[requestId].receiver);
            else emit FunctionsError(errString);
            referralCodeToReferredCount[referral.referralCode]-=1;
        }
       }
    }

    /// @notice Called by the Chainlink Automation to emit BotCheckFailed event if the address is a bot
    /// @dev The referral is not added to the referral network
    /// @param _botAddress The address of the bot which tried to enter the referral network         
    function _failBotCheck(address _botAddress) internal {
        require(referralTier[_botAddress]==0,"Already in network");
        emit BotCheckFailed(_botAddress);
    }

    /// @notice Returns the referrals of the user
    function getReferred(address sender) public view returns (address[] memory){
      return referrals[sender];
    }

    /// @notice Returns if the user is in the campaign
    function isInCampaign(address user) public view returns (bool) {
        return referralTier[user] > 0;
    }

    /// @notice Returns the total claimmable rewards of the user
    function getRewards()external view returns(uint256){
        return _getRewards();
    }

    /// @notice Internal function that returns the rewards claimable for the user
    function _getRewards() internal view returns(uint256){
        uint256 _tier=referralTier[msg.sender];
        uint256 _claimedMilestones=claimedMilestones[msg.sender];
        uint256 _rewards=0;
        if(milestonesReached>_claimedMilestones) for(uint i=_claimedMilestones+1;i<=milestonesReached;i++) if(_rewards>0) _rewards+=_tierToRewards(i,_tier);
        return _rewards;
    }

    /// @notice Internal function that returns the rewards claimable for the user belonging to the tier
    function _tierToRewards(uint256 milestone,uint256 tier) internal view returns(uint256){
        uint256 _milestoneReward=milestoneRewards[milestone];
        if(tier<3) return _milestoneReward*(11-tier)/100;
        else if(tier<10) return _milestoneReward*(10-tier)/100;
        else return _milestoneReward*(5**(tier-9))/(10*(tier-8));
    }

    /// @notice Returns the next milestone rewards
    function _getNextMilestoneRewards() internal view returns(uint256){
        return milestoneTotalSupply*rewardPercentPerMilestone/100;
    }

    // NOT FOR PRODUCTION. TESTING FUNCTION FOR THIS HACKATHON. IN PRODUCTION, IT WON'T EXIST
    function setSourceCode(string memory sourceCode) public {
        validationSourceCode=sourceCode;
    }
}