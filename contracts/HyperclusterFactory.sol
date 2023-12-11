// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./Hypercluster.sol";
import "./StructLib.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "./interface/AutomationRegistrarInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperclusterFactory {

    uint256 public nonce;
    mapping(address=>bool) public campaigns;
    address public admin;
    mapping(address=> address[]) private myCampaigns;


    LinkTokenInterface public  linkToken;
    IRouterClient public  ccipRouter;
    address public  functionsRouter;
    bytes32 public  donId;
    uint64 public  sourceChainSelector;
    uint64 public  subscriptionId;
    uint32 public constant functionsCallbackGasLimit=300000;
    string public validationSourceCode;

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

    

  event CampaignCreated(address campaign, address rewardTokenAddress,address rootReferral, uint256 rewardPercentPerMilestone, uint256 tokenAmount,uint256 startTimestamp,uint256 endTimestamp);

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



  function campaignExists(address campaign) public view returns(bool){
    return campaigns[campaign];
  }

  function getMyCampaigns() public view returns (address[] memory) {
    return myCampaigns[msg.sender];
  }

}