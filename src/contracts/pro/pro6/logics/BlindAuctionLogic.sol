// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "../libraries/BlindAuctionLib.sol";
import "../AbstractBasicAuction.sol";
import "../storages/BlindAuctionStorage.sol";
import "../interfaces/BlindAuctionInterface.sol";
import "forge-std/console2.sol";

contract BlindAuctionLogic is
    AbstractBasicAuction,
    BlindAuctionInterface,
    BlindAuctionStorage
{
    function init(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress,
        address _pointAddress,
        address _myApeAddress,
        uint _tokenId
    ) public {
        require(!initStatus, "Already init");
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
        revealEndTime = auctionEndTime + revealTime;
        initStatus = true;
        pointAddress = _pointAddress;
        myApeAddress = _myApeAddress;
        tokenId = _tokenId;
    }

    /// 设置一个盲拍。
    function bid(
        bytes32 blindedBid
    ) external payable onlyBefore(auctionEndTime) {
        console2.logBytes32(blindedBid);
        bids[msg.sender].push(
            BlindAuctionLib.Bid({blindedBid: blindedBid, deposit: msg.value})
        );
        // 记录拍卖用户，不重复
        if (!containsElement(auctioneers, msg.sender)) {
            auctioneers.push(msg.sender);
        }
        emit SomeoneBid(msg.sender);
    }

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external onlyAfter(auctionEndTime) onlyBefore(revealEndTime) {
        BlindAuctionLib.BidReveal memory bidReveal = BlindAuctionLib.BidReveal(
            values,
            fakes,
            secrets
        );
        emit RevealDetail(values, fakes, secrets);
        (
            uint256 lastHighestBid,
            address lastHighestBidder,
            uint256 refund
        ) = BlindAuctionLib.reveal(
                bids[msg.sender],
                bidReveal,
                highestBid,
                highestBidder
            );
        // 解析之后，假如当前出价比历史最高出价还高
        // 新的出价高于当前最高出价
        if (lastHighestBid > highestBid) {
            console2.log("BlindAuctionLogic reveal lastHighestBid:%s, lastHighestBidder:%s, refund:%s===============", lastHighestBid, lastHighestBidder, refund);
            highestBid = lastHighestBid;
            highestBidder = lastHighestBidder;
            // reveal完成，删除此竞拍者的拍卖记录
            delete bids[msg.sender];
            payable(msg.sender).transfer(refund);
            // 初始时，历史最高出价为0，且用户地址为0
            if (highestBidder != address(0)) {
                // Refund the previously highest bidder.
                pendingReturns[highestBidder] += highestBid;
            }
        }
        emit SomeoneReveal(msg.sender, values, fakes, secrets);
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd()
        public
        override(AbstractBasicAuction, AuctionInterface)
        onlyAfter(revealEndTime)
    {
        AbstractBasicAuction.auctionEnd();
    }
}