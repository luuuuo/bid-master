// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionEvents {
    event SomeoneBid(address bidder);
    event SomeoneReveal(address bidder);
    event AuctionEnded();
    event RevealDetail(uint[] values, bool[] fakes, string[] secrets);
}