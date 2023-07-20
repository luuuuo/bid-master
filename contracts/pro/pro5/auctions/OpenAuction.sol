// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "./AuctionOwnerController.sol";

import "../storages/OpenAuctionStorage.sol";

contract OpenAuction is AuctionOwnerController, OpenAuctionStorage{

    function getImplementationPosition() public override pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-open");
    }

    function getOwnerPosition() public override pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-open-owner");
    }

    function init(uint biddingTime, address payable beneficiaryAddress) public {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's operation");
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,address)", biddingTime, beneficiaryAddress)
        );
        require(success, "Delegatecall failed");
        setOwnership(msg.sender);
    }

    function bid() external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("bid()")
        );
        require(success, "Delegatecall failed");
    }

    function withdraw() external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        if (!success) {
            console.logBytes(result);
            revert(abi.decode(result, (string)));
        }
    }
}