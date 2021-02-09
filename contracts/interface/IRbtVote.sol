// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IRbtVote{
    //获取token的拥有者
    function ownerOf(uint256 tokenId) external view returns(address);
    //获取一个用户拥有多少令牌
    function balanceOf(address addr) external view returns(uint);
    
     //获取总共增发token数量
    function totalSupply() external view returns(uint);
    
    //进行授权
    function approve(address to, uint256 tokenId) external;
    
    //转移NFT所有权
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
   
    //转移NFT所有权 
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    //令牌转账
    function transfer(address from, address to, uint256 tokenId) external;
    
    //授予地址_operator具有所有NFTs的控制权，成功后需触发ApprovalForAll事件
    function setApprovalForAll(address operator, bool _approved) external;
    
    //用来是否查询授权
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    //用来查询授权
    function getApproved(uint256 _tokenId) external view returns (address);
    
    //配置要查询的合约地址和基础权重比例
    function  setPriorVotes (address[] memory addr,uint [] memory ratio) external;

    //查询委托的票数
    function getcommissionedVotes(address addr,uint campaignId) external view returns (uint);

    //投票减票
    function subcommissionedVotes(address addr,uint campaignId,uint amount) external;

    //获取某次投票总共委托的票数
    function getDelegateVote(uint campaignId) external view  returns(uint);

}