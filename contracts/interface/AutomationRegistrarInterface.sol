// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {RegistrationParams} from "../StructLib.sol";

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}
