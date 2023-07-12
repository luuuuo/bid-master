// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionErrors {
    error BidNotHighEnough(uint highestBid);
    error AuctionEndAlreadyCalled();
}