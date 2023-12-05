

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;



contract Safe{

    address public campaignAddress;

    function initialize(address _campaignAddress) public {
        campaignAddress = _campaignAddress;
    }
}