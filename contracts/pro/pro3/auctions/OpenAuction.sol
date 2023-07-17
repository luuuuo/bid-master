// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";

contract OpenAuction{

    bytes32 private constant implementationPosition = keccak256("bid-master-open");
    bytes32 private constant ownerPosition = keccak256("bid-master-open-owner");
    function upgradeTo(address newImplementation) public {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's upgrade");
        bytes32 newImplementationPosition = implementationPosition;
        bytes32 newOwnerPosition = ownerPosition;
        address owner = msg.sender;
        assembly {
            sstore(newImplementationPosition, newImplementation)
            sstore(newOwnerPosition, owner)
        }
    }

    function getOwnerAddress() public view returns(address ownerAddress) {
        bytes32 position = ownerPosition;
        assembly {
            ownerAddress := sload(position)
        }
    }

    function getImplementation() public view returns(address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    function init(uint biddingTime, address payable beneficiaryAddress) public {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,address)", biddingTime, beneficiaryAddress)
        );
        require(success, "Delegatecall failed");
    }

    function bid() external payable {
        console.log("bid()--------------------------------------");   
        console.logBytes(msg.data);
        // 使用 delegatecall 调用逻辑合约中的函数
        console.logBytes(abi.encodeWithSignature("bid()"));
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