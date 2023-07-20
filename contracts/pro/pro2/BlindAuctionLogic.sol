// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "./BlindAuctionLib.sol";
import "./AuctionErrors.sol";
import "./AuctionEvents.sol";
import "./BlindAuctionStorage.sol";
contract BlindAuctionLogic is AuctionEvents, AuctionErrors, BlindAuctionStorage{
    // 使用 修饰符（modifier） 可以更便捷的校验函数的入参。
    // 'onlyBefore' 会被用于后面的 'bid' 函数：
    // 新的函数体是由 modifier 本身的函数体，其中'_'被旧的函数体所取代。
    modifier onlyBefore(uint time) {
        // if (block.timestamp >= time) revert OnlyCanBeCallBeforeThisTime();
        _;
    }
    modifier onlyAfter(uint time) {
        // if (block.timestamp <= time) revert OnlyCanBeCallAfterThisTime();
        _;
    }

    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress) public {
        require(!initStatus,"Already init");

        beneficiary = beneficiaryAddress;
        bidEndTime = block.timestamp + biddingTime;
        revealEndTime = bidEndTime + revealTime;

        initStatus = true;
    }
    /// 设置一个盲拍。
    function bid(bytes32 blindedBid) external payable onlyBefore(bidEndTime) {
        bids[msg.sender].push(BlindAuctionLib.Bid({ blindedBid: blindedBid, deposit: msg.value }));
        emit SomeoneBid(msg.sender);
    }
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external onlyAfter(bidEndTime) onlyBefore(revealEndTime) {
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
    function auctionEnd() external onlyAfter(revealEndTime) {
        if (ended)
            revert AuctionEndAlreadyCalled();
        ended = true;
        beneficiary.transfer(highestBid);
        emit AuctionEnded();
    }
}