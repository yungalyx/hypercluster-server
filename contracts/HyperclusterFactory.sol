// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../contracts/HyperclusterCampaign.sol";

contract HyperclusterFactory {

  address[] public campaigns; 

  uint64 public sourceChainSelector ;
  address public immutable i_link;
  address public router;

  mapping(address => bool) public isCampaign;

  event CampaignCreated(address campaign_address, address creator);

  constructor(uint64 _sourceChainSelector, address _link,address _router)
  {
    sourceChainSelector = _sourceChainSelector;
    i_link = _link;
    router=_router;
  }


  function createCampaign(string calldata name, address reward_token, address datafeed_address) public payable returns(address)  {
    // find price of erc20 token, set that in campaign

    bytes32 _salt = keccak256(abi.encodePacked(name, reward_token, tx.origin, datafeed_address));

    address c = address(new HyperclusterCampaign{salt: _salt}(name, reward_token, tx.origin, datafeed_address,  sourceChainSelector,  i_link,router));

    // HyperclusterCampaign c = new HyperclusterCampaign(name, reward_token, tx.origin, datafeed_address);
    campaigns.push(c);
    emit CampaignCreated(c, tx.origin);
    return address(c);
  }

  function getCampaigns() public view returns (address[] memory) {
    return campaigns;
  }


  function campaignExists(address campaign) public view returns(bool){
    return isCampaign[campaign];
  }
}



