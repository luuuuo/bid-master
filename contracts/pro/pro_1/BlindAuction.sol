// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "hardhat/console.sol";
import "./BlindAuctionLib.sol";
import "./AuctionErrors.sol";
import "./AuctionEvents.sol";
import "./AuctionModifier.sol";

contract BlindAuction is AuctionEvents, AuctionErrors, AuctionModifier{
    mapping(address => BlindAuctionLib.Bid[]) public bids;
    // 拍卖的当前状态。
    address public highestBidder;
    uint public highestBid;
    // 允许取回以前的竞标。
    mapping(address => uint) public pendingReturns;
    // 拍卖结束后设为 'true'，将禁止所有的变更，默认初始化为 'false'。
    bool ended;

    // 拍卖的参数。
    // 时间是 unix 的绝对时间戳（自1970-01-01以来的秒数）
    // 或以秒为单位的时间段。
    uint public bidEndTime;
    uint public revealEndTime;
    address payable public beneficiary;
    /// 以受益者地址 'beneficiaryAddress' 创建一个简单的拍卖，拍卖时长为 '_biddingTime'。
    constructor(
        uint biddingTime,
        uint revealTime, 
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        bidEndTime = block.timestamp + biddingTime;
        revealEndTime = bidEndTime + revealTime;
    }

    /// 可以通过 '_blindedBid' = keccak256(value, fake, secret)
    /// 设置一个盲拍。
    /// 只有在出价披露阶段被正确披露，已发送的以太币才会被退还。
    /// 如果与出价一起发送的以太币至少为 "value" 且 "fake" 不为真，则出价有效。
    /// 将 "fake" 设置为 true ，
    /// 然后发送满足订金金额但又不与出价相同的金额是隐藏实际出价的方法。
    /// 同一个地址可以放置多个出价。
    function bid(bytes32 blindedBid) external payable onlyBefore(bidEndTime) {
        bids[msg.sender].push(BlindAuctionLib.Bid({ blindedBid: blindedBid, deposit: msg.value }));
        emit SomeOneBid(msg.sender);
    }

    /// 撤回出价过高的竞标。
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 将其设置为0是很重要的，
            // 因为接收者可以在 'send' 返回之前再次调用这个函数
            // 作为接收调用的一部分。
            pendingReturns[msg.sender] = 0;
            // msg.sender 不属于 'address payable' 类型，
            // 必须使用 'payable(msg.sender)' 明确转换，
            // 以便使用成员函数 'transfer()'。
            payable(msg.sender).transfer(amount);
        }
    }


    /// 披露你的盲拍出价。
    /// 对于所有正确披露的无效出价以及除最高出价以外的所有出价，您都将获得退款。
    /// 未披露的盲拍将竞拍无效
    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        string[] calldata secrets
    ) external onlyAfter(bidEndTime) onlyBefore(revealEndTime) {
        BlindAuctionLib.BidReveal memory bidReveal = BlindAuctionLib.BidReveal(values, fakes, secrets);
        // for (uint i = 0; i < length; i++) {
        //     (uint value, bool fake, string memory secret) = (bidReveal.values[i], bidReveal.fakes[i], bidReveal.secrets[i]);
        //     console.log("=======value===========", value);
        //     console.log("=======fake===========", fake);
        //     console.logString(secret);
        //     console.logBytes32(bids[msg.sender][i].blindedBid);
        //     console.logBytes32(keccak256(abi.encode(value, fake, secret)));
        // }
        (uint256 lastHighestBid, address lastHighestBidder, uint256 refund) = BlindAuctionLib.reveal(bids[msg.sender], bidReveal, highestBid, highestBidder);
        highestBid = lastHighestBid;
        highestBidder = lastHighestBidder;
        delete bids[msg.sender];
        payable(msg.sender).transfer(refund);
        emit SomeOneReveal(msg.sender);
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external onlyAfter(revealEndTime) {
        // 对于可与其他合约交互的函数（意味着它会调用其他函数或发送以太币），
        // 一个好的指导方针是将其结构分为三个阶段：
        // 1. 检查条件
        // 2. 执行动作 (可能会改变条件)
        // 3. 与其他合约交互
        // 如果这些阶段相混合，其他的合约可能会回调当前合约并修改状态，
        // 或者导致某些效果（比如支付以太币）多次生效。
        // 如果合约内调用的函数包含了与外部合约的交互，
        // 则它也会被认为是与外部合约有交互的。
        // 1. 条件
        if (ended)
            revert AuctionEndAlreadyCalled();
        // 2. 影响
        ended = true;
        // 3. 交互
        beneficiary.transfer(highestBid);
        emit AuctionEnded();
    }
}