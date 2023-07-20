// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionStorage.sol";

contract OpenAuctionStorage is AuctionStorage{
    mapping(address => uint) public pendingReturns;
}