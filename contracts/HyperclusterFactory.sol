// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../contracts/HyperclusterCampaign.sol";

contract HyperclusterFactory {

  address[] public campaigns; 
  address private functionRouter;

  event CampaignCreated(address campaign_address, address creator);

  constructor(address _functionRouter) public {
    functionRouter = _functionRouter;
  }

  function createCampaign(string calldata name, address reward_token, address _datafeed) public payable returns(address)  {
    // find price of erc20 token, set that in campaign

    bytes32 _salt = keccak256(abi.encodePacked(name, reward_token, tx.origin, _datafeed, functionRouter));

    address c = address(new HyperclusterCampaign{salt: _salt}(name, reward_token, tx.origin, _datafeed, functionRouter));

    // HyperclusterCampaign c = new HyperclusterCampaign(name, reward_token, tx.origin, datafeed_address);
    campaigns.push(c);
    emit CampaignCreated(c, tx.origin);
    return address(c);
  }

  function getCampaigns() public view returns (address[] memory) {
    return campaigns;
  }

}



