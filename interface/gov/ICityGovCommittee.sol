pragma solidity ^0.8.0;

interface ICityGovCommittee {
    function getAreaIdByCityId(uint id) external  view returns(uint);
}
