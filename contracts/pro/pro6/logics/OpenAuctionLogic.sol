// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/OpenAuctionInterface.sol";
import "../AbstractBasicAuction.sol";
import "../errors/AuctionErrors.sol";
import "../events/AuctionEvents.sol";
import "../storages/OpenAuctionStorage.sol";
import "../ERC721/MyApeInterface.sol";
import "hardhat/console.sol";

contract OpenAuctionLogic is
    AbstractBasicAuction,
    OpenAuctionInterface,
    OpenAuctionStorage
{
    function init(
        uint biddingTime,
        address payable beneficiaryAddress,
        address _pointAddress,
        address _myApeAddress,
        uint _tokenId
    ) public {
        require(!initStatus, "Already init");
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
        initStatus = true;
        pointAddress = _pointAddress;
        myApeAddress = _myApeAddress;
        tokenId = _tokenId;
    }

    function bid() external payable onlyBefore(auctionEndTime) {
        if (msg.value <= highestBid) revert BidNotHighEnough(highestBid);
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        // 记录拍卖用户，不重复
        if (!containsElement(auctioneers, msg.sender)) {
            auctioneers.push(msg.sender);
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
    function auctionEnd()
        public
        override(AbstractBasicAuction, AuctionInterface)
        onlyAfter(auctionEndTime)
    {
        AbstractBasicAuction.auctionEnd();
    }

    function init(
        uint biddingTime,
        address payable beneficiaryAddress,
        address _pointAddress,
        address _collectionAddress,
        address _owner,
        uint _tokenId
    ) external override {}
}