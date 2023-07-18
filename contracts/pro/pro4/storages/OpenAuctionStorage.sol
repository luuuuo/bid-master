// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract OpenAuctionStorage {
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public pendingReturns;
    bool ended;
}