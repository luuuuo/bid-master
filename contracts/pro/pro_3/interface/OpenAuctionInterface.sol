// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionInterface.sol";

interface OpenAuctionInterface is AuctionInterface {
    function bid() external;
    function withdraw() external;
}