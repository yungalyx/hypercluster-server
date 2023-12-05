// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;



interface IHyperclusterFactory{


    function campaignExists(address _campaign) external view returns(bool);
}