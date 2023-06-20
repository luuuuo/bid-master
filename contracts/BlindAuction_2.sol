// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BlindAuction_3 {
    // 拍卖的当前状态。
    address public highestBidder;
    uint public highestBid;

    /// 已经有一个更高的或相等的出价。
    error BidNotHighEnough(uint highestBid);
    
    // 允许取回以前的竞标。
    mapping(address => uint) public pendingReturns;

    /// 对拍卖进行出价，具体的出价随交易一起发送。
    function bid() external payable{
        // 如果出价不高，就把钱送回去
        //（revert语句将恢复这个函数执行中的所有变化，
        // 包括它已经收到钱）。
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}