// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../contracts/HyperclusterCampaign.sol";

contract HyperclusterFactory {

  address[] public campaigns; 

  event CampaignCreated(address campaign_address, address creator);

  function createCampaign(string calldata name, address erc20) public payable returns(address)  {
    // find price of erc20 token, set that in campaign
    HyperclusterCampaign c = new HyperclusterCampaign(name, erc20, tx.origin);
    campaigns.push(address(c));
    emit CampaignCreated(address(c), tx.origin);
    return address(c);
  }


}



