// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "../interface/ICampaign.sol";
import "../interface/ISafe.sol";

contract HyperclusterFactory {

    uint256 public nonce;
    mapping(address=>bool) public campaigns;
    address public campaignImplementation;
    address public safeImplementation;
    address public admin;


    constructor(address _campaignImplementation)
    {
      campaignImplementation = _campaignImplementation;
      admin = msg.sender;
      nonce = 0;
    }


    event CampaignCreated(address campaign, address safeAddress, address rewardTokenAddress,address rootReferral, uint256 rewardPercentPerMilestone, uint256 tokenAmount,uint256 startTimestamp,uint256 endTimestamp,string metadata);


    // First create Safe
    // Then create campaign
    // Initialize Safe with campaign address
    // Emit event

  function createCampaign(ICampaign.CreateCampaignParams memory params) public payable returns(address)  {

    ISafe safe=ISafe(_deployProxy(safeImplementation, nonce));
    ICampaign campaign = ICampaign(_deployProxy(campaignImplementation, nonce));
    
    safe.initialize(address(campaign)); 
    campaign.initialize(params,address(safe));

    emit CampaignCreated(
      address(campaign),
      address(safe),
      params.rewardTokenAddress,
      params.rootReferral,
      params.rewardPercentPerMilestone,
      params.totalSupply,
      block.timestamp+params.startIn,
      block.timestamp+params.endIn,
      params.metadata);
    campaigns[address(campaign)]=true;
    nonce++;
    return address(campaign);
  }

  function _deployProxy(
        address implementation,
        uint salt
    ) internal returns (address _contractAddress) {
        bytes memory code = _creationCode(implementation, salt);
        _contractAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );
        if (_contractAddress.code.length != 0) return _contractAddress;

        _contractAddress = Create2.deploy(0, bytes32(salt), code);
    }

    function _creationCode(
        address implementation_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_)
            );
    }


  function campaignExists(address campaign) public view returns(bool){
    return campaigns[campaign];
  }
}