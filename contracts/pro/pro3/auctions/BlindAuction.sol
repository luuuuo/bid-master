// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "./AuctionOwnerController.sol";
import "../storages/BlindAuctionStorage.sol";

contract BlindAuction is AuctionOwnerController, BlindAuctionStorage{

    function getImplementationPosition() public override pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-blind");
    }

    function getOwnerPosition() public override pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-blind-owner");
    }

    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress) public {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's operation");
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,uint256,address)", biddingTime, revealTime, beneficiaryAddress)
        );
        require(success, "Delegatecall failed");
        setOwnership(msg.sender);
    }

    function bid(bytes32 _value) external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("bid(bytes32)", _value)
        );
        require(success, "Delegatecall failed");
    }

    function reveal(uint[] calldata values, bool[] calldata fakes, string[] calldata secrets) external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("reveal(uint256[],bool[],string[])", values, fakes, secrets)
        );
        if (!success) {
            console.logBytes(result);
            revert(abi.decode(result, (string)));
        }
    }
}