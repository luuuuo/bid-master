// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./AuctionOwnerController.sol";
import "../ERC20/BidMasterPointInterface.sol";
import "../ERC721/MyApeInterface.sol";
import "../storages/OpenAuctionStorage.sol";

contract OpenAuction is AuctionOwnerController,OpenAuctionStorage{

    function getImplementationPosition() public override pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-open");
    }

    function getOwnerPosition() public override pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-open-owner");
    }

    function init(uint biddingTime, address payable beneficiaryAddress, address _pointAddress, address _collectionAddress, uint _tokenId) public onlyOwner(){
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,address,address,address,uint256)", biddingTime, beneficiaryAddress, _pointAddress, _collectionAddress, _tokenId)
        );
        require(success && result.length == 0, "delegatecall failed");
        setOwnership(msg.sender);
    }

    function bid() external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("bid()")
        );
        require(success && result.length == 0, "delegatecall failed");
    }

    function withdraw() external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        require(success && result.length == 0, "delegatecall failed");
    }
    
    function auctionEnd() public{
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("auctionEnd()")
        );
        require(success && result.length == 0, "delegatecall failed1");
    }

}