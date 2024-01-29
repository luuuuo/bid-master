// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./errors/AuctionErrors.sol";
import "./events/AuctionEvents.sol";
import "./interfaces/AuctionInterface.sol";
import "./storages/AuctionStorage.sol";

abstract contract AbstractBasicAuction is AuctionInterface, AuctionErrors, AuctionEvents, AuctionStorage{
    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() public virtual {
        if (ended)
            revert AuctionEndAlreadyCalled();
        ended = true;
        beneficiary.transfer(highestBid);
        emit AuctionEnded();
    }
}