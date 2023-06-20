// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract SimpleAuction {
    // 拍卖的参数。
    // 时间是 unix 的绝对时间戳（自1970-01-01以来的秒数）
    // 或以秒为单位的时间段。
    uint public auctionEndTime;

    // 拍卖的当前状态。
    address public highestBidder;
    uint public highestBid;

    /// 拍卖时长为 `_biddingTime`。
    constructor(
        uint biddingTime
    ) {
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// 对拍卖进行出价，具体的出价随交易一起发送。
    /// 如果没有在拍卖中胜出，则返还出价。
    function bid() external {
        
    }

    /// 撤回出价过高的竞标。
    function withdraw() external returns (bool) {
        return true;
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external {

    }
}