// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionOwnerController.sol";

contract BlindAuction is AuctionOwnerController{

    function getImplementationPosition() public override pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-blind");
    }

    function getOwnerPosition() public override pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-blind-owner");
    }

    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress, address _pointAddress, address _collectionAddress, uint _tokenId) public onlyOwner(){
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("init(uint256,uint256,address,address,address,uint256)", biddingTime, revealTime, beneficiaryAddress, _pointAddress, _collectionAddress, _tokenId)
        );
        require(success && result.length == 0, "delegatecall failed");
        setOwnership(msg.sender);
    }

    function bid(bytes32 _value) external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("bid(bytes32)", _value)
        );
        require(success && result.length == 0, "delegatecall failed");
    }

    function reveal(uint[] calldata values, bool[] calldata fakes, string[] calldata secrets) external {
        // 使用 delegatecall 调用逻辑合约中的函数
        // console.log("------------------");
        // console.logBytes(msg.data);
        // console.log("==================");
        // console.logBytes(abi.encodeWithSignature("reveal(uint256[],bool[],string[])", values, fakes, secrets));
        (bool success, bytes memory result) = getImplementation().delegatecall(
            abi.encodeWithSignature("reveal(uint256[],bool[],string[])", values, fakes, secrets)
        );
        require(success && result.length == 0, "delegatecall failed");
    }

    function auctionEnd() external{
        // console.log("------------------");
        // console.logBytes(msg.data);
        // console.log("==================");
        // console.logBytes(abi.encodeWithSignature("auctionEnd()"));
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, bytes memory result ) = getImplementation().delegatecall(
            abi.encodeWithSignature("auctionEnd()")
        );
        require(success && result.length == 0, "delegatecall failed");
    }

}