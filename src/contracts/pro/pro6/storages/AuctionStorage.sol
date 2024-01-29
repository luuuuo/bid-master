// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionStorage {
    address payable public beneficiary;
    bool internal initStatus = false;
    mapping(address => uint) public pendingReturns;
    // 拍卖是否结束标识
    bool ended;
    // 拍卖结束时间，只有在此之前才可以出价
    uint public auctionEndTime;
    // 当前最高出价者
    address public highestBidder;
    // 当前最高出价
    uint public highestBid;
    // 竞拍获得的积分
    address public pointAddress;
    // 竞拍标的物
    address public myApeAddress;
    // 竞拍标的物id
    uint public tokenId;
    // 竞拍参与者
    address[] public auctioneers;
}