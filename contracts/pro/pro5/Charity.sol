// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Charity {
    struct Donation {
        address donor;
        uint256 amount;
        uint256 timestamp;
    }

    Donation[] public donations;

    receive() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        donations.push(Donation({
            donor: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));
    }
    
}