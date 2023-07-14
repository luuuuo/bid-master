// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./BlindAuctionStorage.sol";
import "hardhat/console.sol";
import "./BlindAuctionLogicInterface.sol";

contract BlindAuction is BlindAuctionStorage{
    BlindAuctionLogicInterface blindAuctionLogicInterface;
    address public immutable AUCTION_LOGIC_ADDRESS;
    constructor(
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress,
        address auctionLogicAddress
    ) {
        beneficiary = beneficiaryAddress;
        bidEndTime = block.timestamp + biddingTime;
        revealEndTime = bidEndTime + revealTime;
        AUCTION_LOGIC_ADDRESS = auctionLogicAddress;
        blindAuctionLogicInterface = BlindAuctionLogicInterface(auctionLogicAddress);
    }
    
    function bid(bytes32 _value) external payable {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = AUCTION_LOGIC_ADDRESS.delegatecall(
            abi.encodeWithSignature("bid(bytes32)", _value)
        );
        require(success, "Delegatecall failed");
    }

    function withdraw() external {
        // 使用 delegatecall 调用逻辑合约中的函数
        (bool success, ) = AUCTION_LOGIC_ADDRESS.delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "Delegatecall failed");
    }

    function reveal(uint[] calldata values, bool[] calldata fakes, string[] calldata secrets) external {
        // 使用 delegatecall 调用逻辑合约中的函数
        for (uint i = 0; i < values.length; i++) {
            (uint value, bool fake, string memory secret) = (values[i], fakes[i], secrets[i]);
            console.log("=======value===========", value);
            console.log("=======fake===========", fake);
            console.logString(secret);
            console.logBytes32(bids[msg.sender][i].blindedBid);
            console.logBytes32(keccak256(abi.encode(value, fake, secret)));
        }
        console.log("=======delegatecall start===========", address(blindAuctionLogicInterface));
        blindAuctionLogicInterface.reveal(values, fakes, secrets);
        // (bool success, bytes memory result) = AUCTION_LOGIC_ADDRESS.delegatecall(
        //     abi.encodeWithSignature("reveal(uint[], bool[], string[])", values, fakes, secrets)
        // );
        // console.log("=======success===========", success);
        // if (!success) {
        //     // handle exception here
        //     console.logBytes(result);
        //     revert(abi.decode(result, (string)));
        // }
        
        // require(success, abi.decode(result, (string)));
        console.log("=======delegatecall end===========");
    }
}