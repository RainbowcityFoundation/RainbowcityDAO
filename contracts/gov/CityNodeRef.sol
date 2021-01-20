pragma solidity ^0.8.0;
import '../interface/gov/ICityNode.sol';
import '../interface/gov/IParliament.sol';

abstract contract CityNodeRef {
    ICityNode public cityNode;
    IParliament public Ip;
    constructor(address nodeAddress )   {
        cityNode = ICityNode(nodeAddress);
         Ip = IParliament(nodeAddress);
    }

    modifier _inNode(uint nodeId,address sender) {
        require(Ip.inNode(nodeId,sender), "not in");
        _;
    }
    modifier _inVotePeriod(uint nodeId){
        (bool votePeriod, , ,) = Ip.getCityNodeInfo(nodeId);
        require(votePeriod,'not in vote time');
        _;
    }



}
