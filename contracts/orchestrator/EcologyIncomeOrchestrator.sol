// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../income/EcologyIncome.sol";

contract EcologyIncomeOrchestrator is Initializable {

    address public ecologyIncome;

    function init(address manager) external initializer {

        ecologyIncome = address(new EcologyIncome(manager));

    }
    
}