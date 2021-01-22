// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {userVipStruct} from '../lib/userVipStruct.sol';

interface IRbtVip{
    //用户注册
    function register(uint referrerId, string calldata nickname) external;

    //购买vip
    function exchangeVip(uint vipNumber,address token) external;


    //查询用户vip等级
    function getVipLevel(address addr) external view returns(uint);
    
    //获取令牌的token
    function tokenOfOwnerByIndex(address owner,uint index) external view returns(uint);
    
    //获取用户详情
    function getUserInfo(address addr) external view returns(userVipStruct.User memory);

    //获取失效token最大值，便于查询多少失效令牌
    function getAllVipIneffective() external  view returns (uint maxExTokenId);

    //获取个人失效token最大值，便于个人查询多少失效令牌
    function getOwerVipIneffective(address addr) external view returns (uint maxOwnerExTokenId);
    
    //获取token的拥有者
    function ownerOf(uint256 tokenId) external view returns(address);

    //获取vip详情信息
    function  getVipInfo(uint256 tokenId)  external  view  returns(userVipStruct.Vip memory );
    
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
    
}