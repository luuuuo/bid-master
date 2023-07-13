// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./BlindAuctionStorage.sol";

contract BlindAuction is BlindAuctionStorage{
    address public immutable AUCTION_LOGIC_ADDRESS;
    constructor(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress,
        address auctionLogicAddress
    ) {
        beneficiary = beneficiaryAddress;
        bidEndTime = block.timestamp + biddingTime;
        revealEndTime = bidEndTime + revealTime;
        AUCTION_LOGIC_ADDRESS = auctionLogicAddress;
    }
    
    function bid(bytes32 _value) external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = AUCTION_LOGIC_ADDRESS.delegatecall(
            abi.encodeWithSignature("bid(bytes32)", _value)
        );
        require(success, "Delegatecall failed");
    }

    function withdraw() external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = AUCTION_LOGIC_ADDRESS.delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "Delegatecall failed");
    }

    function reveal() external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = AUCTION_LOGIC_ADDRESS.delegatecall(
            abi.encodeWithSignature("reveal(uint[], bool[], string[])")
        );
        require(success, "Delegatecall failed");
    }
}