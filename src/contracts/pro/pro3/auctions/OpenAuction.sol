// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "forge-std/console2.sol";
import "./AuctionOwnerController.sol";

contract OpenAuction is AuctionOwnerController{

    function getImplementationPosition() public override pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-open");
    }

    function getOwnerPosition() public override pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-open-owner");
    }

    function init(uint biddingTime, address payable beneficiaryAddress) public onlyOwner(){
        console2.log("================beneficiaryAddress:", beneficiaryAddress);
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,address)", biddingTime, beneficiaryAddress)
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
        require(success && result.length == 0, "delegatecall failed");
    }
}