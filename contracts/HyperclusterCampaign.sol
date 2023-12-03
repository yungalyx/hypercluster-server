// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperclusterCampaign is FunctionsClient, ConfirmedOwner{
  using FunctionsRequest for FunctionsRequest.Request;


  // fields: organize this pls 
  AggregatorV3Interface internal dataFeed;
  bool public isActive;
  bool public locked;
  string public name;
  address public campaignOwner;
  address public rewardToken;
  int public startPrice;
  address[] users;

  uint64 public sourceChainSelector ;
  address public router;
  address public immutable i_link;
  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  address private currentWithdrawer;

  mapping(address=>uint256) public rewards;
  // block.timestamp

  // events
  event ReferralAdded(address referrer, address refferred);
  event RewardClaimed(address user, uint256 amt_claimed);
  event TokensSent(bytes32 messageId, address receiver, uint256 amount, uint64 destinationChainSelector);
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

  constructor(string memory _name, address _erc20, address _owner, address _datafeed ,uint64 _sourceChainSelector, address _link,address _router) public
    FunctionsClient(0xb83E47C2bC239B3bf370bc41e1459A34b41238D0) 
    ConfirmedOwner(msg.sender) {
    // router for sepolia 
  sourceChainSelector=_sourceChainSelector;
    isActive = false;
    campaignOwner = _owner;
    name = _name;
    rewardToken = _erc20;
    dataFeed = AggregatorV3Interface(_datafeed);
    i_link=_link;

    router=_router;
  }

  function getStartPrice() private view returns (int) {
    ( /* uint80 roundID */,
      int answer,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();
    return answer;

  }

  function acceptReferral(address referrer) external onlyActive() {
    users.push(tx.origin);
    emit ReferralAdded(referrer, tx.origin);
  }

  function deposit(uint256 _amount) public {
    startPrice = getStartPrice();
    require(_amount>0, "Invalid Deposit");
    require(IERC20(rewardToken).allowance(tx.origin, address(this)) >= _amount, "Approve tokens first");
    IERC20(rewardToken).transferFrom(tx.origin, address(this), _amount);
    isActive = true;
  }

  function claimRewards(uint64 _destinationChainSelector) public noReentrancy() {
    if (checkUserInCampaign(tx.origin)) {
      require(IERC20(rewardToken).balanceOf(address(this))>rewards[tx.origin], "Rewards depleted");
      if(_destinationChainSelector==sourceChainSelector||_destinationChainSelector==0)
      {
        IERC20(rewardToken).transfer(tx.origin, rewards[tx.origin]);
      }else{
        // THE REWARD TOKEN MUST BE CCIP-BnM or CCIP-LnM
        _sendRewardsCrosschain(tx.origin, rewards[tx.origin],  _destinationChainSelector);
      }
      // calculate their rewards from off chain and redistribute
      // sendRequest(); // TODO
    } 
  }

  function _sendRewardsCrosschain(address receiver, uint256 amount,  uint64 _destinationChainSelector) internal {
        IERC20(rewardToken).approve(router, amount);
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: rewardToken, amount: amount});
         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: "",
            feeToken: i_link 
        });

        uint256 fee = IRouterClient(router).getFee(
            _destinationChainSelector,
            message
        );
      require(LinkTokenInterface(i_link).balanceOf(address(this))>=fee, "Not enough LINK");
        bytes32 messageId;
        LinkTokenInterface(i_link).approve(router, fee);
            messageId = IRouterClient(router).ccipSend(
                _destinationChainSelector,
                message
            );
        emit TokensSent(messageId, receiver,amount,_destinationChainSelector);
        
    }


  // view function costs less gas 
  function checkUserInCampaign(address _user) private view returns (bool) {
     for (uint i = 0; i < users.length; i++) {
        if (users[i] == _user) {
            return true;
        }
    }
    return false;
  }

  // TODO
  string source =
        "const characterId = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://swapi.dev/api/people/${characterId}/`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeUint256(data.balance);";

  uint32 gasLimit = 300000;

  bytes32 donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000; // ETH Sepolia

  function sendRequest(
      uint64 subscriptionId,
      string[] calldata args,
      address user
    ) private returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        currentWithdrawer = user;

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;

  }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
          revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        // character = string(response);
        string memory amount = string(response);
        (uint256 amt, bool valid) = strToUint(amount);
        if (valid) {
           fulfillClaimRewards(requestId, amt);
        } 

        s_lastError = err;



        // Emit an event to log the response
        //emit Response(requestId, character, s_lastResponse, s_lastError);
    }

    function fulfillClaimRewards(bytes32 requestId, uint256 amt) public {
      require(amt > 0, "No rewards to be claimed");
      IERC20(rewardToken).transfer(currentWithdrawer, amt);
      emit RewardClaimed(currentWithdrawer, amt);
    }

    function strToUint(string memory _str) public pure returns(uint256 res, bool err) {
      
      for (uint256 i = 0; i < bytes(_str).length; i++) {
          if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
              return (0, false);
          }
          res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
      }
    
      return (res, true);
    }

}