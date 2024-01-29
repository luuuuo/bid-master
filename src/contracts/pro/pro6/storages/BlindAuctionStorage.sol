// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./../libraries/BlindAuctionLib.sol";
import "./AuctionStorage.sol";

contract BlindAuctionStorage is AuctionStorage{
    mapping(address => BlindAuctionLib.Bid[]) public bids;
    // 披露结束时间，只有在此之前才可以披露
    uint public revealEndTime;
}