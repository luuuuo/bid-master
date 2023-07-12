// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionEvents {
    event SomeOneBid(address bidder);
    event SomeOneReveal(address bidder);
    event AuctionEnded();
}