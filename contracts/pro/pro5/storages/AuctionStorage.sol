// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionStorage {
    address payable public beneficiary;
    bool internal initStatus = false;
    // 拍卖是否结束标识
    bool ended;
    // 拍卖结束时间
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;

}