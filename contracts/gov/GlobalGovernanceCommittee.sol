pragma solidity ^0.8.0;

import '../interface/gov/IGlobalGovernanceCommittee.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "../ref/CommunityGovernanceFundRef.sol";
contract GlobalGovernanceCommittee is IGlobalGovernanceCommittee , CommunityGovernanceFundRef{


    address public area;
    constructor(address core,address voteIdAddr,address areaGov)   CommunityGovernanceFundRef(core,voteIdAddr)  {
        area = areaGov;
    }
    modifier onlyAreaGov() {
        require(
            msg.sender == area,
            "Global: Caller is not a AreaGov"
        );
        _;
    }

    function activeGov() public override onlyAreaGov{
        require(cgInfo.active == false,'already active');
        cgInfo.impeachIndex = 12;
        cgInfo.active == true;
    }
}
