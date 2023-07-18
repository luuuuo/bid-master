// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";

contract AuctionOwnerController{

    function getImplementationPosition() public virtual pure returns(bytes32 implementationPosition){
        implementationPosition = keccak256("bid-master-open");
    }

    function getOwnerPosition() public virtual pure returns(bytes32 ownerPosition){
        ownerPosition = keccak256("bid-master-open-owner");
    }

    function upgradeTo(address newImplementation) public {
        require(getOwnerAddress() == msg.sender, "not owner's operation");
        bytes32 newImplementationPosition = getImplementationPosition();
        assembly {
            sstore(newImplementationPosition, newImplementation)
        }
    }

    function setOwnership(address _newOwner) public {
        if(getOwnerAddress() != address(0))
            require(getOwnerAddress() == msg.sender, "not owner's operation");
        require(_newOwner != address(0));
        bytes32 newOwnerPosition = getOwnerPosition();
        assembly {
            sstore(newOwnerPosition, _newOwner)
        }
    }

    function getOwnerAddress() public view returns(address ownerAddress) {
        bytes32 position = getOwnerPosition();
        assembly {
            ownerAddress := sload(position)
        }
    }

    function getImplementation() public view returns(address impl) {
        bytes32 position = getImplementationPosition();
        assembly {
            impl := sload(position)
        }
    }
}