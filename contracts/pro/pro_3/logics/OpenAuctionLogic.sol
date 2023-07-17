// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract OpenAuctionLogic {
    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    error BidNotHighEnough(uint highestBid);
    error AuctionEndAlreadyCalled();
    error OnlyCanBeCallAfterThisTime();
    error OnlyCanBeCallBeforeThisTime();

    mapping(address => uint) public pendingReturns;
    bool ended;
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert OnlyCanBeCallBeforeThisTime();
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert OnlyCanBeCallAfterThisTime();
        _;
    }
    constructor(
        uint biddingTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
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