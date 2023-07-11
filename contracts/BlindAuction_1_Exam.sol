// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BlindAuction_1 {
    // 拍卖的当前状态。
    address public highestBidder;
    uint public highestBid;
    /// 对拍卖进行出价，具体的出价随交易一起发送。
    function bid() external payable{
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}