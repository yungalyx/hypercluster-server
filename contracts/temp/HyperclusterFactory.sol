// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "../interface/ICampaign.sol";


contract HyperclusterFactory {

    uint256 public nonce;
    mapping(address=>bool) public campaigns;
    address public campaignImplementation;
    address public safeImplementation;
    address public admin;
    mapping(address=> address[]) private myCampaigns;


    constructor(address _campaignImplementation)
    {
      campaignImplementation = _campaignImplementation;
      admin = msg.sender;
      nonce = 0;
    }

    event CampaignCreated(address campaign, address rewardTokenAddress,address rootReferral, uint256 rewardPercentPerMilestone, uint256 tokenAmount,uint256 startTimestamp,uint256 endTimestamp);


  function createCampaign(
    Create) public returns(address)
  {
    // ISafe safe=ISafe(_deployProxy(safeImplementation, nonce));
    ICampaign campaign = ICampaign(_deployProxy(campaignImplementation, nonce));

    ICampaign.CreateCampaignParams memory params = ICampaign.CreateCampaignParams(
        rewardTokenAddress,
        rootReferral,
        rewardPercentPerMilestone,
        totalSupply,
        startIn,
        endIn
    );
    
    // safe.initialize(address(campaign)); 
    campaign.initialize(params);

    emit CampaignCreated(
      address(campaign),
      rewardTokenAddress,
      rootReferral,
      rewardPercentPerMilestone,
      totalSupply,
      block.timestamp+startIn,
      block.timestamp+endIn);

    
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

  function getMyCampaigns() public view returns (address[] memory) {
    return myCampaigns[msg.sender];
  }
}