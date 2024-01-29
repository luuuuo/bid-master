// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./AuctionInterface.sol";

interface BlindAuctionInterface is AuctionInterface {
    // 相比公开拍卖，盲拍此处初始化函数将多一个披露截止时间
    function init(uint biddingTime, uint revealTime, address payable beneficiaryAddress, address _pointAddress, address _collectionAddress, uint _tokenId) external;

    function bid(bytes32 _value) payable external;

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external;
}