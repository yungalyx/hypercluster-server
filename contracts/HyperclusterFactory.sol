// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./StructLib.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "./interface/AutomationRegistrarInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ICampaign.sol";

contract HyperclusterFactory {

    uint256 public nonce;
    mapping(address=>bool) public campaigns;
    address public campaignImplementation;
    address public safeImplementation;
    address public admin;
    mapping(address=> address[]) private myCampaigns;

    address public constant CCIP_BNM_TOKEN_ADDRESS=0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    LinkTokenInterface public constant LINK_TOKEN=LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    AutomationRegistrarInterface public constant UPKEEP_REGISTRAR=AutomationRegistrarInterface(0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976);

    constructor(address _campaignImplementation)
    {
      campaignImplementation = _campaignImplementation;
      admin = msg.sender;
      nonce = 0;
    }

    event CampaignCreated(address campaign, address rewardTokenAddress,address rootReferral, uint256 rewardPercentPerMilestone, uint256 tokenAmount,uint256 startTimestamp,uint256 endTimestamp);

  function createCampaign(CreateCampaignParams memory params) public returns(address)
  {
    require(IERC20(CCIP_BNM_TOKEN_ADDRESS).allowance(msg.sender,address(this))>params.totalSupply,"Approve Tokens first");
    ICampaign campaign = ICampaign(_deployProxy(campaignImplementation, nonce));

    campaign.initialize(params,msg.sender);

    emit CampaignCreated(
      address(campaign),
      params.rewardTokenAddress,
      params.rootReferral,
      params.rewardPercentPerMilestone,
      params.totalSupply,
      block.timestamp+params.startIn,
      block.timestamp+params.endIn);

    
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