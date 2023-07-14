// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface BlindAuctionLogicInterface {
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external;
}