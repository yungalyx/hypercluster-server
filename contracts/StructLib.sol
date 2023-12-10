// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


    struct CreateCampaignParams{
        address rewardTokenAddress;
        address rootReferral;
        uint256 rewardPercentPerMilestone;
        uint256 totalSupply;
        uint256 startIn;
        uint256 endIn;
        string metadata;
    }
