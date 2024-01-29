// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "forge-std/console2.sol";

/*
将原来的合约中的结构体和方法都封装到了一个库合约BlindAuctionLib中，并将原来的合约变成了一个使用这个库合约的外部合约。
在这个库合约中，定义了一些新的结构体和方法，用于对拍卖的状态进行操作。外部合约只需要引用这个库合约，并使用其中的方法即可。
 */
library BlindAuctionLib {

    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }
    struct BidReveal {
        uint[] values;
        bool[] fakes;
        string[] secrets;
    }
    error RevealMsgError(uint value, bool fake, string secret);

    function reveal(
        Bid[] calldata blindInfo,
        BidReveal calldata bidReveals,
        uint256 highestBid,
        address highestBidder
    ) external view returns (uint256 lastHighestBid, address lastHighestBidder, uint256 refund){
        uint length = blindInfo.length;
        require(bidReveals.values.length == length);
        require(bidReveals.fakes.length == length);
        require(bidReveals.secrets.length == length);
        for (uint i = 0; i < length; i++) {
            Bid memory bidToCheck = blindInfo[i];
            (uint value, bool fake, string memory secret) = (bidReveals.values[i], bidReveals.fakes[i], bidReveals.secrets[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encode(value, fake, secret))) {
                revert RevealMsgError(value, fake, secret);
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value && value > highestBid) {
                highestBid = value;
                highestBidder = msg.sender;
                refund -= value;
            }
        }
        return (highestBid, highestBidder, refund);
    }
}