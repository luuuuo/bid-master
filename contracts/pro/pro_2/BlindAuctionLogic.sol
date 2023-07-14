// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "./BlindAuctionLib.sol";
import "./AuctionErrors.sol";
import "./AuctionEvents.sol";
import "./AuctionModifier.sol";
import "./BlindAuctionStorage.sol";
contract BlindAuctionLogic is AuctionEvents, AuctionErrors, AuctionModifier, BlindAuctionStorage{
    constructor() {}
    /// 设置一个盲拍。
    function bid(bytes32 blindedBid) external payable onlyBefore(bidEndTime) {
        bids[msg.sender].push(BlindAuctionLib.Bid({ blindedBid: blindedBid, deposit: msg.value }));
        emit SomeoneBid(msg.sender);
    }
    /// 撤回出价过高的竞标。
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }
    /// 披露你的盲拍出价。
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