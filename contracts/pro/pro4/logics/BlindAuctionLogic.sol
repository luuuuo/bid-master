// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "../libraries/BlindAuctionLib.sol";
import "../AbstractBasicAuction.sol";
import "../storages/BlindAuctionStorage.sol";
import "../interfaces/BlindAuctionInterface.sol";

contract BlindAuctionLogic is AbstractBasicAuction, BlindAuctionInterface, BlindAuctionStorage{

    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress) public {
        require(!initStatus,"Already init");
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
        revealEndTime = auctionEndTime + revealTime;
        initStatus = true;
    }
    
    /// 设置一个盲拍。
    function bid(bytes32 blindedBid) external payable onlyBefore(auctionEndTime) {
        bids[msg.sender].push(BlindAuctionLib.Bid({ blindedBid: blindedBid, deposit: msg.value }));
        emit SomeoneBid(msg.sender);
    }
    
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external onlyAfter(auctionEndTime) onlyBefore(revealEndTime) {
        BlindAuctionLib.BidReveal memory bidReveal = BlindAuctionLib.BidReveal(values, fakes, secrets);
        emit RevealDetail(values, fakes, secrets);
        (uint256 lastHighestBid, address lastHighestBidder, uint256 refund) = BlindAuctionLib.reveal(bids[msg.sender], bidReveal, highestBid, highestBidder);
        highestBid = lastHighestBid;
        highestBidder = lastHighestBidder;
        delete bids[msg.sender];
        payable(msg.sender).transfer(refund);
        emit SomeoneReveal(msg.sender);
    }
    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() public override(AbstractBasicAuction, AuctionInterface) onlyAfter(revealEndTime) {
        AbstractBasicAuction.auctionEnd();
    }
}