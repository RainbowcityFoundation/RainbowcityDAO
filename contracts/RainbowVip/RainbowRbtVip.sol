// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

import "../lib/TransferHelper.sol";
import "../lib/TokenSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../ref/CoreRef.sol";
import "../interface/IRbtVip.sol";
import "../interface/IERC721Receiver.sol";

contract RainbowRbtVip is CoreRef, IRbtVip {
    using SafeMath
    for uint; //Security library
    using Set
    for Set.TokenIdSet; //set library
    string public name = "RVIP";
    string public symbol = "RVIP";

    uint public validity = 365 days; //Default validity period of the token
    uint256 public vipPrice; //Token price
    address public FoundationAddress; //Foundation address
    address public RBTEX; //rbtex address
    uint private initialNum = 20090103; //Initial user registration number

    userVipStruct.Vip[] public vipArray; //All vip

    userVipStruct.User[] public userListArray; //All user 

    mapping(address => Set.TokenIdSet) vipNum; //address --token gather

    mapping(address => uint) public referrerMaps; // user address——user ID

    mapping(uint256 => address) private _tokenApprovals; // tokenId----Authorized address

    mapping(address => mapping(address => bool)) private _operatorApprovals; //Approval of mapping from address to address

    event Register(uint indexed newId, uint indexed referrerId); //Registered user event


    event Transfer(address indexed from, address indexed to, uint256 value); //ERC721 Transfer event

    event TransferFundation(address indexed tokenAddr, address indexed from, address indexed to, uint256 value); //Foundation transfer event

    event Approval(address indexed owner, address indexed spender, uint256 value); //Authorization event

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //initialization
    constructor(uint _price, address _foundationAddress, address _rbtex, address core) CoreRef(core) public {
        vipPrice = _price;
        FoundationAddress = _foundationAddress;
        RBTEX = _rbtex;
        userVipStruct.User memory user = userVipStruct.User({
            id: initialNum, // The ID of the new user is the latest ID
            addrRef: address(0), //The referrer of the first user is '0' address
            registerTime: block.timestamp, //The current time is the registration time
            nickname: 'admin', //admin is Default nickname
            userAddress: msg.sender, //user address
            childs: new address[](0) //The initial generation is '0'
        });
        userListArray.push(user); //Join array
        emit Register(initialNum, 0);
    }

    //User registration
    function register(uint referrerId, string calldata nickname) override external {
        require(referrerMaps[msg.sender] == 0, "user exists");
        uint newId = initialNum + userListArray.length;
        address refAddress = userListArray[referrerId - initialNum].userAddress;
        userVipStruct.User memory user = userVipStruct.User({
            id: newId, // The ID of the new user is the latest ID
            addrRef: refAddress,
            registerTime: block.timestamp,
            nickname: nickname,
            userAddress: msg.sender, //user address
            childs: new address[](0)
        });
        userListArray.push(user);
        userListArray[referrerId - initialNum].childs.push(msg.sender); //Newil recommended users under the referrer
        referrerMaps[msg.sender] = newId;
        TransferHelper.safeTransfer(RBTEX, msg.sender, 1000e18);
        emit Register(newId, referrerId);
    }

    //Redeem VIP tokens(number of tokens,token address)
    function exchangeVip(uint vipNumber, address token) override public {
        require(vipNumber > 0, "The amount is insufficient");
        uint amount = vipNumber.mul(vipPrice);
        for (uint i = 0; i < vipNumber; i++) {
            mint(msg.sender);
        }
        //The amount of vip income is managed by the basis of controlling dividends
        TransferHelper.safeTransferFrom(token, msg.sender, FoundationAddress, amount);
        emit TransferFundation(token, msg.sender, FoundationAddress, amount * 10 ** 18);
    }

    //Get vip level  
    function getVipLevel(address addr) public view override returns(uint) {
        uint256 num = vipNum[addr].length();
        if (num == 0) {
            return 0;
        }
        uint8 level = 0;
        for (uint i = 0; i < num; i++) {
            if (vipArray[vipNum[addr].at(i) - 1].expireTime > block.timestamp) {
                level++;
            }
        }
        if (level < 9) {
            return level / 3 + 1;
        }
        return 4;
    }


    //View the max token of all expired tokens
    function getAllVipIneffective() public view override returns(uint maxExTokenId) {
        for (uint i = 0; i < vipArray.length; i++) {
            userVipStruct.Vip memory vip = vipArray[i];
            if (vip.expireTime > block.timestamp) {
                break;
            }
            maxExTokenId = vip.tokenId;
        }
    }

    //View the token with the longest personal expiration time
    function getOwerVipIneffective(address addr) public view override returns(uint maxOwnerExTokenId) {
        uint num = vipNum[addr].length();
        uint maxOwnerExpireTime = vipArray[vipNum[addr].at(0) - 1].expireTime;
        for (uint i = 0; i < num; i++) {
            if (vipArray[vipNum[addr].at(i) - 1].expireTime > maxOwnerExpireTime) {
                maxOwnerExpireTime = vipArray[vipNum[addr].at(i) - 1].expireTime;
                maxOwnerExTokenId = vipArray[vipNum[addr].at(i) - 1].tokenId;
            }
        }
    }

    //Query token owner
    function ownerOf(uint256 tokenId) public view override returns(address) {
        return vipArray[tokenId - 1].owner;
    }

    //Query the details of the token 
    function getVipInfo(uint256 tokenId) public view override returns(userVipStruct.Vip memory) {
        return vipArray[tokenId - 1];
    }

    //Query user's details
    function getUserInfo(address addr) public view override returns(userVipStruct.User memory) {
        if (referrerMaps[msg.sender] != 0) {
            return userListArray[referrerMaps[addr] - initialNum];
        }
    }

    //Additonal token issuance
    function mint(address to) internal returns(uint) {
        require(to != address(0), "ERC721: mint to the zero address");
        uint256 newTokenId = vipArray.length + 1;
        userVipStruct.Vip memory vip = userVipStruct.Vip({
            owner: to,
            creator: to,
            tokenId: newTokenId,
            expireTime: block.timestamp + validity,
            crtTime: block.timestamp
        });
        vipArray.push(vip);
        vipNum[msg.sender].add(newTokenId);
        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    // The admin presents a token to the user
    function sendVipByWhiteList(address[] memory addr, uint[] memory amount) onlyGovernor public {
        require(addr.length == amount.length, "ArrayLenght err,The length should be the same");
        for (uint i = 0; i < addr.length; i++) {
            for (uint j = 0; j < amount[i]; j++) {
                mint(addr[i]);
            }
        }
    }

    //Get the token of the user token
    function tokenOfOwnerByIndex(address owner, uint index) public override view returns(uint) {
        return vipNum[owner].at(index);
    }

    //Get how many tokens a user has
    function balanceOf(address addr) public view override returns(uint) {
        return vipNum[addr].length();
    }

    //Get the total number of additional tokens
    function totalSupply() public view override returns(uint) {
        return vipArray.length;
    }

    //To authotize
    function approve(address to, uint256 tokenId) public override {
        address ownerAddr = vipArray[tokenId - 1].owner;
        require(to != ownerAddr, "ERC721: approval to current owner");
        require(msg.sender == ownerAddr, "ERC721: approve caller is not owner ");
        _tokenApprovals[tokenId] = ownerAddr;
        emit Approval(ownerAddr, to, tokenId);
    }

    //Transfer
    function transfer(address from, address to, uint256 tokenId) public override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        vipNum[from].remove(tokenId);
        vipNum[to].add(tokenId);
        vipArray[tokenId - 1].owner = to;
        emit Transfer(from, to, tokenId);
    }

    //Transfer NFT ownership
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    //Transfer NFT ownership
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    //Grant address '_operator' to have control of all NFTs
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //Check whether it is authorized
    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    //Check whether it is authorized
    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(vipArray[tokenId - 1].owner != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    //The internal function is called at the target address.If the target address is not a contract,the call is not executed.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns(bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    function isContract(address account) internal view returns(bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}