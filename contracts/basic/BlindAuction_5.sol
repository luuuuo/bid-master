// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BlindAuction_5 {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }
    
    mapping(address => Bid[]) public bids;

    // 拍卖的参数。
    // 时间是 unix 的绝对时间戳（自1970-01-01以来的秒数）
    // 或以秒为单位的时间段。
    address payable public beneficiary;
    uint public auctionEndTime;

    // 拍卖的当前状态。
    address public highestBidder;
    uint public highestBid;

    /// 已经有一个更高的或相等的出价。
    error BidNotHighEnough(uint highestBid);
    /// 函数 auctionEnd 已经被调用。
    error AuctionEndAlreadyCalled();
    /// 仅允许在此时间后调用
    error OnlyCanBeCallAfterThisTime();
    /// 仅允许在此时间前调用
    error OnlyCanBeCallBeforeThisTime();

    // 允许取回以前的竞标。
    // 拍卖结束后设为 'true'，将禁止所有的变更
    // 默认初始化为 'false'。
    bool ended;
    // 使用 修饰符（modifier） 可以更便捷的校验函数的入参。
    // 'onlyBefore' 会被用于后面的 'bid' 函数：
    // 新的函数体是由 modifier 本身的函数体，其中'_'被旧的函数体所取代。
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert OnlyCanBeCallBeforeThisTime();
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert OnlyCanBeCallAfterThisTime();
        _;
    }
    /// 以受益者地址 'beneficiaryAddress' 创建一个简单的拍卖，
    /// 拍卖时长为 '_biddingTime'。
    constructor(
        uint biddingTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// 可以通过 '_blindedBid' = keccak256(value, fake, secret)
    /// 设置一个盲拍。
    /// 只有在出价披露阶段被正确披露，已发送的以太币才会被退还。
    /// 如果与出价一起发送的以太币至少为 "value" 且 "fake" 不为真，则出价有效。
    /// 将 "fake" 设置为 true ，
    /// 然后发送满足订金金额但又不与出价相同的金额是隐藏实际出价的方法。
    /// 同一个地址可以放置多个出价。
    function bid(bytes32 blindedBid) external payable onlyBefore(auctionEndTime) {
        bids[msg.sender].push(Bid({ blindedBid: blindedBid, deposit: msg.value }));
    }

   
    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external onlyAfter(auctionEndTime) {
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
    }
}