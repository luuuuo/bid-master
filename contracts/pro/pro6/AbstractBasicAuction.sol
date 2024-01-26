// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
import "./errors/AuctionErrors.sol";
import "./events/AuctionEvents.sol";
import "./interfaces/AuctionInterface.sol";
import "./storages/AuctionStorage.sol";
import "./ERC20/BidMasterPointInterface.sol";
import "./ERC721/MyApeInterface.sol";
import "hardhat/console.sol";

abstract contract AbstractBasicAuction is AuctionInterface, AuctionErrors, AuctionEvents, AuctionStorage{
    
    function containsElement(address[] memory auctioneers, address element) public pure returns (bool) {
        uint256 length = auctioneers.length;
        for (uint256 i = 0; i < length; i++) {
            if (auctioneers[i] == element) {
                return true; // 存在特定元素
            }
        }
        return false; // 不存在特定元素
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() public virtual{
        if (ended)
            revert AuctionEndAlreadyCalled();
        ended = true;
        (bool success, bytes memory result) = beneficiary.call{value: highestBid}("");
        require(success && result.length == 0, "transfer ETH failed");
        // 发放参与积分
        for (uint i = 0; i < auctioneers.length; i++) {
            BidMasterPointInterface(pointAddress).mint(auctioneers[i], 10);
        }
        /// 发放NFT给竞拍获胜者
        MyApeInterface(myApeAddress).transferFrom(msg.sender, highestBidder, tokenId);
        emit AuctionEnded();
    }
}