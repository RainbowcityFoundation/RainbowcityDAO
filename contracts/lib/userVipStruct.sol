// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library  userVipStruct {
    struct User {
        uint id; // 用户ID
        address addrRef;// 推荐人地址
        string nickname;//用户昵称
        address userAddress; //用户地址
        uint registerTime; //注册时间
        address[] childs;//推荐列表
    }
    
    struct Vip{
        address owner; //拥有者
        address creator;//原始生产者
        uint tokenId; //tokenId号
        uint crtTime;//生成时间
        uint expireTime;//过期时间
       
    }

}
