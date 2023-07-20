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

    address public blindAuctionImpl;
    address public openAuctionImpl;

    event AuctionCreated(address indexed _newAuctionAddr, address indexed _creator,AuctionType _auctionType);

    modifier onlyOwner() {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's operation");
        _;
    }

    constructor(address _blindAuctionImpl, address _openAuctionImpl) {
        blindAuctionImpl = _blindAuctionImpl;
        openAuctionImpl = _openAuctionImpl;
        setOwnership(msg.sender);
    }

    function createAuctions(AuctionType _auctionType) external returns (address auctionAddress) {
        // 创建新合约
        if(_auctionType == AuctionType.Blind){
            BlindAuction blindAuction = new BlindAuction();
            blindAuction.upgradeTo(blindAuctionImpl);
            blindAuction.setOwnership(msg.sender);
            auctionAddress = address(blindAuction); 
        }else{
            OpenAuction openAuction = new OpenAuction();
            openAuction.upgradeTo(openAuctionImpl);
            openAuction.setOwnership(msg.sender);
            auctionAddress = address(openAuction);
        }
        userAuctions[msg.sender].push(Auctions(_auctionType, auctionAddress));
        emit AuctionCreated(auctionAddress,msg.sender, _auctionType);
        
        return auctionAddress;
    }

    function setNewBlindAuctionImpl(address _newBlindAuctionImpl) external onlyOwner{
        require(_newBlindAuctionImpl != address(0),"The new BlindAuctionImpl address cannot be 0x00");
        blindAuctionImpl = _newBlindAuctionImpl;
    }

    function setNewOpenAuctionImpl(address _newOpenAuctionImpl) external onlyOwner{
        require(_newOpenAuctionImpl != address(0),"The new OpenAuctionImpl address cannot be 0x00");
        openAuctionImpl = _newOpenAuctionImpl;
    }

    function getOwnerPosition() public virtual pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("auction-factory-owner");
    }
    
    function getOwnerAddress() public view returns(address ownerAddress) {
        bytes32 position = getOwnerPosition();
        assembly {
            ownerAddress := sload(position)
        }
    }

    function setOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0));
        bytes32 newOwnerPosition = getOwnerPosition();
        assembly {
            sstore(newOwnerPosition, _newOwner)
        }
    }
}