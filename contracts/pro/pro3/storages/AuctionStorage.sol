// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionStorage {
    address payable public beneficiary;
    bool internal initStatus = false;
    // 拍卖是否结束标识
    bool ended;
    // 拍卖结束时间
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;

}