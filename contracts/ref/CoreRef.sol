// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interface/ref/ICoreRef.sol";

import "@openzeppelin/contracts/utils/Address.sol";


abstract contract CoreRef is ICoreRef {
    ICore private _core;
    
    constructor(address core)  {
        _core = ICore(core);
    }
    
    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyCityNode() {
        require(_core.isCityNode(msg.sender),"CoreRef: Caller is not a CityNode");
        _;
    }
    modifier onlyVote() {
        require(_core.isVote(msg.sender),"CoreRef: Caller is not a Vote");
        _;
    }



    function setCore(address core) external override onlyGovernor {
        _core = ICore(core);
        emit CoreUpdate(core);
    }
    
     /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }
    
       /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function Rbt() public view override returns (IERC20) {
        return _core.rbt();
    }

}