// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionInterface.sol";

interface OpenAuctionInterface is AuctionInterface {
    function init(uint biddingTime, address payable beneficiaryAddress) external;

    function bid() payable external;

    function withdraw() external;
}