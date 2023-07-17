// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionInterface.sol";

interface BlindAuctionInterface is AuctionInterface {
    function bid(bytes32 _value) external;

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external;
}