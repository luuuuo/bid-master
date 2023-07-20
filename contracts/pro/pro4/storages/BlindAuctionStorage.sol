// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./../libraries/BlindAuctionLib.sol";

contract BlindAuctionStorage {
    mapping(address => BlindAuctionLib.Bid[]) public bids;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public pendingReturns;
    bool ended;
    uint public bidEndTime;
    uint public revealEndTime;
    address payable public beneficiary;

    bool internal initStatus = false;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}