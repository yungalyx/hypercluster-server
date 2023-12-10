// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "../StructLib.sol";

interface ICampaign{

    function initialize(CreateCampaignParams memory params,uint256 _upKeepId,address creator) external returns(bool);
}