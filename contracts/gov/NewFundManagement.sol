pragma solidity ^0.8.0;
import './CityNodeFundManagement.sol';
import '../interface/gov/INewFundManagement.sol';
import "../ref/CoreRef.sol";
contract NewFundManagement is INewFundManagement,CoreRef{
    constructor(address core) public  CoreRef(core)   {}
    function newInit() external override onlyCityNode returns(address){
        CityNodeFundManagement _cfm = new CityNodeFundManagement(address(this),address(core()),address(Rbt()));
        return address(_cfm);
    }
}
