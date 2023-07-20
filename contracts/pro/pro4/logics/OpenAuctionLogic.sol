// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../interfaces/OpenAuctionInterface.sol";
import "../AbstractBasicAuction.sol";
import "../errors/AuctionErrors.sol";
import "../events/AuctionEvents.sol";
import "../storages/OpenAuctionStorage.sol";

contract OpenAuctionLogic is AbstractBasicAuction, OpenAuctionInterface, OpenAuctionStorage{

    function init(uint biddingTime, address payable beneficiaryAddress) public {
        require(!initStatus,"Already init");

        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;

        initStatus = true;

    }

    function bid() external payable onlyBefore(auctionEndTime) {
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    /// 撤回出价过高的竞标。
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external onlyAfter(auctionEndTime) {
        if (ended)
            revert AuctionEndAlreadyCalled();
        ended = true;
        beneficiary.transfer(highestBid);
    }
}