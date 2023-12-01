// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HyperclusterCampaign is FunctionsClient, ConfirmedOwner{
  using FunctionsRequest for FunctionsRequest.Request;

  // fields: organize this pls 
  AggregatorV3Interface internal datafeed;
  bool public isActive;
  bool public locked;
  string public name;
  address public owner;
  address public rewardToken;
  int public startPrice;
  address[] users;

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  address private currentWithdrawer;

  
  // block.timestamp

  // events
  event ReferralAdded(address referrer, address refferred);
  event RewardClaimed(address user, uint256 amt_claimed);

  // errors
  error UnexpectedRequestID(bytes32 requestId);

  // modifiers
  modifier noReentrancy() {
    require(!locked, "No reentrancy");
    locked = true;
    _;
    locked = false;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner"); 
    _;
  }
  
  modifier isActive() {
    require(isActive == true, "Campaign is not active");
  }

  constructor(string memory _name, address _erc20, address _owner, address _datafeed) internal {
    FunctionsClient(0xb83E47C2bC239B3bf370bc41e1459A34b41238D0); // router for sepolia 
    ConfirmedOwner(msg.sender);
    isActive = false;
    owner = _owner;
    name = _name;
    rewardToken = _erc20;
    datafeed = AggregatorV3Interface(_datafeed);
    getStartPrice();
    
  }

  function getStartPrice() private {
    ( /* uint80 roundID */,
      int answer,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();
    startPrice = answer;

  }

  function acceptReferral(address referrer) external isActive() {
    users.push(tx.origin);
    emit ReferralAdded(referrer, tx.origin);
  }


  function deposit() public {
    IERC20(rewardToken).transfer(address(this), tx.origin);
    require(IERC20(rewardToken).balanceOf(address(this)) > 0, "Deposit Failed");
    isActive = true;
  }

  function claimRewards() public noReentrancy() {
    if (checkUserInCampaign(tx.origin)) {
      // calculate their rewards from off chain and redistribute
      sendRequest(); // TODO
    } 
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

        fulfillClaimRewards(requestId, response);

        s_lastError = err;



        // Emit an event to log the response
        //emit Response(requestId, character, s_lastResponse, s_lastError);
    }

    function fulfillClaimRewards(bytes32 requestId, bytes response) {
      uint256 amt = uint256(response);
      require(amt > 0, "No rewards to be claimed");
      IERC20(rewardToken).transfer(currentWithdrawer, amt);
      emit RewardClaimed(currentWithdrawer, amt);
    }

}