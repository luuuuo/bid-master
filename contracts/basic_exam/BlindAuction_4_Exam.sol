// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract BlindAuction_4 {

     /**===============错误声明=====================*/
      /// 已经有一个更高的或相等的出价。
    error BidNotHighEnough(uint highestBid);
    /// 函数 auctionEnd 已经被调用。
    error AuctionEndAlreadyCalled();
    /// 仅允许在这时间后调用
    error OnlyCanBeCallAfterThisTime();
    /// 仅允许在这时间前调用
    error OnlyCanBeCallBeforeThisTime();


    /**===============状态变量声明=================*/
        // 拍卖的当前状态。
    address public highestBidder; 
    uint public highestBid; 

    // 允许取回以前的竞标。
    mapping(address => uint) public pendingReturns;


    /***************************** begin ***************************************************/
    //定义一个公共状态变量，命名为beneficiary，用于存储竞拍受益人
    //定义一个公共状态变量，命名为auctionEndTime，用于存储竞拍结束时间  
    //定义一个内部状态变量，命名为ended，用于标识竞拍的结束状态，竞拍结束值为true，布尔值默认为false



    /***************************** end ***************************************************/   

    
      /***************************** begin ***************************************************/
    //定义一个修饰器函数，当当前时间大于竞拍时间，抛出错误OnlyCanBeCallBeforeThisTime（命名为onlyBefore，接收参数为竞拍结束时间）
    


     //定义一个修饰器函数，当当前时间小于竞拍时间，抛出错误OnlyCanBeCallBeforeThisTime（命名为onlyAfter，接收参数为竞拍结束时间）



    /***************************** end ***************************************************/   
   
   
       /***************************** begin ***************************************************/
    //完善构造函数，初始化合约的受益人及拍卖结束时间

    constructor(
        uint biddingTime, //接收拍卖的时长
        address payable beneficiaryAddress  //接收指定的受益人
    ) {
        //初始化受益人
        //初始化拍卖结束时间
    }
  



    /***************************** end ***************************************************/   
 

    /***************************** begin ***************************************************/
    //为出价方法，添加修饰器    
    function bid() external payable (auctionEndTime) {
        // 如果出价不高，就把钱送回去
        //（revert语句将恢复这个函数执行中的所有变化，
        // 包括它已经收到钱）。
        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }
    /***************************** end ***************************************************/   

   

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


    /***************************** begin ***************************************************/
    //完善竞拍结束方法
    //1、添加竞拍结束检测修饰器
    //2、设置结束标记为true
    //3、将最高的出价转账给受益人
     /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external (auctionEndTime) {
        
        if (ended)  //避免多次调用该方法
            revert AuctionEndAlreadyCalled();
        
    }



    /***************************** end ***************************************************/   

   
}