// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./BlindAuctionLib.sol";

contract BlindAuctionStorage {
    mapping(address => BlindAuctionLib.Bid[]) public bids;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public pendingReturns;
    bool ended;
    uint public bidEndTime;
    uint public revealEndTime;
    address payable public beneficiary;
}