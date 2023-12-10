// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


    struct CreateCampaignParams{
        string name;
        string metadata;
        address rewardTokenAddress;
        address rootReferral;
        uint256 rewardPercentPerMilestone;
        uint256 totalSupply;
        uint256 increaseRate;
        uint256 startIn;
        uint256 endIn;
        address dataFeedAddress;
    }


struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}