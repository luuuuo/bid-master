// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./auctions/BlindAuction.sol";
import "./auctions/OpenAuction.sol";

contract AuctionFactory {
    enum AuctionType { Blind, Open }
    struct Auctions{
        AuctionType auctionType;
        address auctionAddress;
    }
    mapping(address => Auctions[]) public userAuctions; 

    function createAuctions(AuctionType _auctionType, address _newImplementation) external returns (address auctionAddress) {
        // 创建新合约
        if(_auctionType == AuctionType.Blind){
            BlindAuction blindAuction = new BlindAuction();
            blindAuction.upgradeTo(_newImplementation);
            blindAuction.setOwnership(msg.sender);
            auctionAddress = address(blindAuction); 
        }else{
            OpenAuction openAuction = new OpenAuction();
            openAuction.upgradeTo(_newImplementation);
            openAuction.setOwnership(msg.sender);
            auctionAddress = address(openAuction);
        }
        userAuctions[msg.sender].push(Auctions(_auctionType, auctionAddress));
        return auctionAddress;
    }
}