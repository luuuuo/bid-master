// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "forge-std/console2.sol";
import "./BlindAuctionStorage.sol";

contract BlindAuction {

    bytes32 private constant implementationPosition = keccak256("bid-master");
    bytes32 private constant ownerPosition = keccak256("bid-master-owner");
    function upgradeTo(address newImplementation) public {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's upgrade");
        bytes32 newImplementationPosition = implementationPosition;
        assembly {
            sstore(newImplementationPosition, newImplementation)
        }
    }

    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress) public {
        // 使用 delegatecall 调用逻辑合约BlindAuctionLogic中的init函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,uint256,address)", biddingTime, revealTime, beneficiaryAddress)
        );
        require(success, "Delegatecall failed");
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

    function bid(bytes32 _value) external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = getImplementation().delegatecall(
            abi.encodeWithSignature("bid(bytes32)", _value)
        );
        require(success, "Delegatecall failed");
    }

    function reveal(uint[] calldata values, bool[] calldata fakes, string[] calldata secrets) external {
        // 使用 delegatecall 调用逻辑合约中的函数
        // msg.data 和 abi.encodeWithSignature("reveal(uint[], bool[], string[])", values, fakes, secrets) 不同？
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("reveal(uint256[],bool[],string[])", values, fakes, secrets)
        );
        if (!success) {
            console2.logBytes(result);
            revert(abi.decode(result, (string)));
        }
    }

    function auctionEnd() external{
        console2.log("------------------");
        console2.logBytes(msg.data);
        console2.log("==================");
        console2.logBytes(abi.encodeWithSignature("auctionEnd()"));
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result ) = getImplementation().delegatecall(
            abi.encodeWithSignature("auctionEnd()")
        );
        require(success && result.length == 0, "delegatecall failed");
    }
}