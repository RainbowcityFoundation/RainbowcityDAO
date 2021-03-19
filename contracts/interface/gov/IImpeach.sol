pragma solidity ^0.8.0;

import {PublicStructs} from '../../utils/PublicStructs.sol';

interface IImpeach {
    function getImpeach(uint id) external view returns (PublicStructs.Impeach memory);

    function setImpeachTickets(uint id, uint tickets) external;

    function setImpeachSuccess(uint id) external;
}
