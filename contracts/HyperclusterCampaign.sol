// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract HyperclusterCampaign is FunctionsClient, ConfirmedOwner{
  using FunctionsRequest for FunctionsRequest.Request;

  // campaign details
  AggregatorV3Interface internal dataFeed;
  bool public isActive;
  bool public locked;
  string public name;
  address public campaignOwner;
  address public rewardToken;

  // reward management
  mapping(address => int256) userTier; // using int256 for base case of first referrer 
  mapping(address=> uint256) alreadyClaimed;
  uint256[] claimableByTier; // index indicates tier  

  uint256 public startPrice;
  uint256 public increaseRate; // 2000 = 20%
  uint256 public thresholdPrice;
  
  // chainlink Functions
  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  address private currentWithdrawer;

  
  // events
  event ReferralAdded(address referrer, address refferred);
  event RewardClaimed(address user, uint256 amt_claimed);
  event Response(bytes32 indexed requestId, bytes response, bytes err);

  // errors
  error UnexpectedRequestID(bytes32 requestId);

  // modifiers
  modifier noReentrancy() {
    require(!locked, "No reentrancy");
    locked = true;
    _;
    locked = false;
  }
  
  modifier onlyActive() {
    require(isActive == true, "Campaign is not active");
    _;
  }

  // setting up for testnet 
  constructor(string memory _name, address _erc20, address _owner, address _pricefeed, address _functionRouter) public
    FunctionsClient(_functionRouter) 
    ConfirmedOwner(msg.sender) {
  
    isActive = false;
    campaignOwner = _owner;
    userTier[_owner] = -1; 
    name = _name;
    rewardToken = _erc20;
    startPrice = setPrice();
    dataFeed = AggregatorV3Interface(_pricefeed);
    
  }

  // only called once during constrcutor 
  function setPrice() private view returns (int) {
    ( /* uint80 roundID */,
      int answer,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();

    thresholdPrice = (answer * increaseRate) / 1e4;
    return answer;

  }

  function updatePrice() private view returns (int) {
    int price = getPrice();
    if (price > thresholdPrice) {
      

    }

  }

  function updateTiers() private {

    for (uint i=0; i<claimableByTier.length; i++) {
      claimableByTier[i] += 
  
    }
    
  }



  // 
  function acceptReferral(address referrer, string memory referrer_code) external onlyActive() {
    require(referrer != msg.sender, "You cannot refer yourself");
    require(checkUserInCampaign(referrer), "Invalid referrer");

    userTier[msg.sender] = userTier[referrer]+1;

    emit ReferralAdded(referrer, msg.sender);
  }


  function deposit(uint256 _amount) external {
    require(_amount > 0);
    // bool approve = IERC20(rewardToken).approve(address(this), _amount);
    // console.log("Approved?", approve);
    IERC20(rewardToken).transferFrom(msg.sender, address(this), _amount);
    require(IERC20(rewardToken).balanceOf(address(this)) > 0, "Deposit Failed");
    isActive = true;
  }

  function claimRewards() public noReentrancy() {
    startPrice = getStartPrice();
    if (checkUserInCampaign(msg.sender)) {
      // calculate their rewards from off chain and redistribute
      // sendRequest(); // TODO
    } 
  }


  function claimRewards() public noReentrancy() {
    require(checkUserInCampaign(msg.sender), "User is not in campaign");

    int256 tier = userTier[msg.sender];
    uint256 amt = claimableByTeir[tier] - alreadyClaimed[msg.sender];
    require(amt > 0, "No rewards can be claimed");

    alreadyClaimed[msg.sender] = claimableByTeir[tier];
    IERC20(rewardToken).transfer(msg.sender, amt);
    emit RewardClaimed(currentWithdrawer, amt);

  }

  // view function costs less gas 
  function checkUserInCampaign(address _user) private view returns (bool) {
    return (keccak256(abi.encodePacked(userTier[_user])) != keccak256(abi.encodePacked(address(0))));
  }

  // // TODO
  // string src =
  //       "const characterId = args[0];"
  //       "const apiResponse = await Functions.makeHttpRequest({"
  //       "url: `https://swapi.dev/api/people/${characterId}/`"
  //       "});"
  //       "if (apiResponse.error) {"
  //       "throw Error('Request failed');"
  //       "}"
  //       "const { data } = apiResponse;"
  //       "return Functions.encodeUint256(data.balance);";

  // uint32 gasLimit = 300000;

  // bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; // ETH Sepolia
  // bytes32 donID2 = 0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000; // mainnet

  // function sendRequest(
  //       string memory source,
  //       bytes memory encryptedSecretsUrls,
  //       uint8 donHostedSecretsSlotID,
  //       uint64 donHostedSecretsVersion,
  //       string[] memory args,
  //       bytes[] memory bytesArgs,
  //       uint64 subscriptionId,
  //       uint32 gasLimit,
  //       bytes32 donID, 
  //       bool useContractSrc
  //   ) external onlyOwner returns (bytes32 requestId) {
  //       FunctionsRequest.Request memory req;
  //       if (useContractSrc) {
  //         req.initializeRequestForInlineJavaScript(src);
  //       } else {
  //         req.initializeRequestForInlineJavaScript(source);
  //       }
        
  //       if (encryptedSecretsUrls.length > 0)
  //           req.addSecretsReference(encryptedSecretsUrls);
  //       else if (donHostedSecretsVersion > 0) {
  //           req.addDONHostedSecrets(
  //               donHostedSecretsSlotID,
  //               donHostedSecretsVersion
  //           );
  //       }
  //       if (args.length > 0) req.setArgs(args);
  //       if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
  //       s_lastRequestId = _sendRequest(
  //           req.encodeCBOR(),
  //           subscriptionId,
  //           gasLimit,
  //           donID
  //       );
  //       return s_lastRequestId;
  //   }

  //   function sendRequestCBOR(
  //       bytes memory request,
  //       uint64 subscriptionId,
  //       uint32 gasLimit,
  //       bytes32 donID
  //   ) external onlyOwner returns (bytes32 requestId) {
  //       s_lastRequestId = _sendRequest(
  //           request,
  //           subscriptionId,
  //           gasLimit,
  //           donID
  //       );
  //       return s_lastRequestId;
  //   }


  //   function fulfillRequest(
  //       bytes32 requestId,
  //       bytes memory response,
  //       bytes memory err
  //   ) internal override {
  //       if (s_lastRequestId != requestId) {
  //           revert UnexpectedRequestID(requestId);
  //       }
  //       s_lastResponse = response;
  //       s_lastError = err;
  //       // _fulfillClaimRewards(requestId, response);
  //       emit Response(requestId, s_lastResponse, s_lastError);

  //   }

  //   function _fulfillClaimRewards(bytes32 requestId, uint256 amt) public {
  //     require(amt > 0, "No rewards to be claimed");
      
   
  //   }

   

}