// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionInterface.sol";

interface BlindAuctionInterface is AuctionInterface {
    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress) external;

    function bid(bytes32 _value) payable external;

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external;
}