// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract AuctionModifier {
    
    error OnlyCanBeCallAfterThisTime();
    error OnlyCanBeCallBeforeThisTime();
    // 使用 修饰符（modifier） 可以更便捷的校验函数的入参。
    // 'onlyBefore' 会被用于后面的 'bid' 函数：
    // 新的函数体是由 modifier 本身的函数体，其中'_'被旧的函数体所取代。
    modifier onlyBefore(uint time) {
        // if (block.timestamp >= time) revert OnlyCanBeCallBeforeThisTime();
        _;
    }
    modifier onlyAfter(uint time) {
        // if (block.timestamp <= time) revert OnlyCanBeCallAfterThisTime();
        _;
    }
}