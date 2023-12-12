// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

// Chainlink and Openzeppelin Imports
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces and Libraries
import "./interface/AutomationRegistrarInterface.sol";
import "./Hypercluster.sol";
import "./StructLib.sol";

/// @title HyperclusterFactory - The Web3 Automated Referral System
/// @author @gabrielantonyxaviour and @yungalyx
/// @notice Submitted for Chailink Constellation 2023 Hackathon
/// @dev Powered by Chainlink Functions, Chainlink CCIP, Chainlink Automation and Chainlink Price Feeds
contract HyperclusterFactory {

    // Public variables
    uint256 public nonce;
    address public admin;
    mapping(address=>bool) public campaigns;
    mapping(address=> address[]) private myCampaigns;

    // Chainlink Variables
    LinkTokenInterface public  linkToken;
    IRouterClient public  ccipRouter;
    address public  functionsRouter;
    bytes32 public  donId;
    uint64 public  sourceChainSelector;
    uint64 public  subscriptionId;
    uint32 public constant functionsCallbackGasLimit=300000;
    string public validationSourceCode;

    // Constructor
    constructor(string memory _validationSourceCode,IRouterClient _ccipRouter,address _functionsRouter, bytes32 _donId,uint64 _sourceChainSelector,uint64 _subscriptionId,LinkTokenInterface _linkToken)
    {
      admin = msg.sender;
      nonce = 0;
      linkToken = _linkToken;
      ccipRouter = _ccipRouter;
      functionsRouter = _functionsRouter;
      donId = _donId;
      sourceChainSelector = _sourceChainSelector;
      subscriptionId = _subscriptionId;
      validationSourceCode = _validationSourceCode;
    }

    
  // Events
  event CampaignCreated(address campaign, address rewardTokenAddress,address rootReferral, uint256 rewardPercentPerMilestone, uint256 tokenAmount,uint256 startTimestamp,uint256 endTimestamp);

   /// @notice Creates a campaign
    /// @dev Deploys the campaign contract, intializes it and transfers the reward tokens into it
    /// @param params campaign specific parameters
    /// @return address returns the address of the deployed campaign contract
  function createCampaign(CreateCampaignParams memory params) public returns(address)
  {
    require(IERC20(params.rewardTokenAddress).allowance(msg.sender,address(this))>params.totalSupply,"Approve Tokens first");
    Hypercluster campaign = new Hypercluster(params,msg.sender,validationSourceCode,linkToken,ccipRouter,functionsRouter,donId,sourceChainSelector,subscriptionId);

    IERC20(params.rewardTokenAddress).transferFrom(msg.sender,address(campaign),params.totalSupply);

      emit CampaignCreated(
        address(campaign),
        params.rewardTokenAddress,
        params.rootReferral,
        params.rewardPercentPerMilestone,
        params.totalSupply,
        block.timestamp+params.startIn,
        block.timestamp+params.endIn);

      myCampaigns[msg.sender].push(address(campaign));
      
      campaigns[address(campaign)]=true;
      nonce++;
      return address(campaign);
    }


  /// @notice Checks if a campaign exists
  function campaignExists(address campaign) public view returns(bool){
    return campaigns[campaign];
  }

  /// @notice Returns the number of campaigns created by a user
  function getMyCampaigns() public view returns (address[] memory) {
    return myCampaigns[msg.sender];
  }

}