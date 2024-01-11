// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.17;
// /***************************** begin ***************************************************/
//     //导入 hardhat/console.sol 库，用于调用console.log输出调试信息
 
// /***************************** end ***************************************************/   

// contract BlindAuction_6 {
//     //盲拍信息：盲拍出价哈希 blindedBid，预存订金 deposit
//     struct Bid {
//         bytes32 blindedBid;
//         uint deposit;
//     }
//     //用于映射每个竞拍者的盲拍信息，竞拍者 => 多次的盲拍信息
//     mapping(address => Bid[]) public bids;

//     //beneficiary:受益人;bidEndTime 竞拍时长;revealEndTime 披露时长 
//     address payable public beneficiary;
//     uint public bidEndTime;
//     uint public revealEndTime;

//     // highestBidder 最高竞拍者; highestBid 最高竞拍价
//     address public highestBidder;
//     uint public highestBid;
    
//     //当前竞拍最高价被迭代后，将上一轮的最高竞拍者信息存储到映射变量pendingReturns以让竞标者赎回
//     mapping(address => uint) public pendingReturns;
//     // 拍卖结束标记 ended
//     bool ended;

//     /// 已经有一个更高的或相等的出价。
//     error BidNotHighEnough(uint highestBid);
//     /// 函数 auctionEnd 已经被调用。
//     error AuctionEndAlreadyCalled();
//     /// 仅允许在此时间后调用
//     error OnlyCanBeCallAfterThisTime();
//     /// 仅允许在此时间前调用
//     error OnlyCanBeCallBeforeThisTime();

    
//     event SomeOneBid(address bidder);
//     event AuctionEnded();
//     /***************************** begin ***************************************************/
//     //声明一个事件,命名为SomeOneReveal，参数竞拍者bidder，用于向区块链发出通知有人进行了披露操作
 
//     /***************************** end ***************************************************/   
   
//     // 使用 修饰符（modifier） 可以更便捷的校验函数的入参。
//     // 'onlyBefore' 会被用于后面的 'bid' 函数：
//     // 新的函数体是由 modifier 本身的函数体，其中'_'被旧的函数体所取代。
//     modifier onlyBefore(uint time) {
//         if (block.timestamp >= time) revert OnlyCanBeCallBeforeThisTime();
//         _;
//     }
//     modifier onlyAfter(uint time) {
//         if (block.timestamp <= time) revert OnlyCanBeCallAfterThisTime();
//         _;
//     }
//     ///初始化构造函数，设置受益人，竞拍时长和披露时长
//     constructor(
//         uint biddingTime,
//         /***************************** begin ***************************************************/
//         //声明一个变量，用于接收合约传入的披露时长 命名为revealTime
 
//         /***************************** end ***************************************************/  
//         address payable beneficiaryAddress
//     ) {
//         beneficiary = beneficiaryAddress;
//         bidEndTime = block.timestamp + biddingTime;
//          /***************************** begin ***************************************************/
//         //声明一个披露结束时间 revealEndTime ,将其初始化为结束时间加披露时长

//         /***************************** end ***************************************************/  
//     }

//     /// 盲拍方法
//     /// 将盲拍出价哈希，携带以太币预存订金一起放到该账户的盲拍信息中，并告知有人参与了盲拍
//     function bid(bytes32 blindedBid) external payable onlyBefore(bidEndTime) {
//         bids[msg.sender].push(Bid({ blindedBid: blindedBid, deposit: msg.value }));
//         emit SomeOneBid(msg.sender);
//     }

//     /// 撤回出价过高的竞标。
//     function withdraw() external {
//         uint amount = pendingReturns[msg.sender];
//         if (amount > 0) {
//             // 将其设置为0是很重要的，
//             // 因为接收者可以在 'send' 返回之前再次调用这个函数
//             // 作为接收调用的一部分。
//             pendingReturns[msg.sender] = 0;
//             // msg.sender 不属于 'address payable' 类型，
//             // 必须使用 'payable(msg.sender)' 明确转换，
//             // 以便使用成员函数 'transfer()'。
//             payable(msg.sender).transfer(amount);
//         }
//     }


//     /// 披露你的盲拍出价。
//     /// 对于所有正确披露的无效出价以及除最高出价以外的所有出价，您都将获得退款。
//     /// 未披露的盲拍将视为无效，不退换订金
//     function reveal(
//         //声明三个数组变量，分别命名为values,fakes,secrets。因为数组是引用类型，默认存储在storage，作为函数参数可以将其保存在calldata，一来减少gas消耗，而来不可修改
//         uint[] calldata values,          
//          /***************************** begin ***************************************************/
//         //声明数组fakes，用于接收当次竞拍是否是伪拍的标记，存放位置在calldata
//         //声明数组secrets，用于接收当次竞拍的密码字符串，存放位置在calldata
         

//         /***************************** end ***************************************************/  
//     ) external onlyAfter(bidEndTime) onlyBefore(revealEndTime) {  // 修改该合约方法只能在竞拍结束之后，披露截止之前执行
//         //检查传入的参数数组长度是否与用户在盲拍阶段提交的出价数量相等。
//         uint length = bids[msg.sender].length;
//         require(values.length == length);
//         require(fakes.length == length);
//         require(secrets.length == length);
//         uint refund; //用于存放返回定金
//          /***************************** begin ***************************************************/
//         //循环遍历竞标者传入的历史竞拍

//                           {  //在此处添加循环语句
//             Bid storage bidToCheck = bids[msg.sender][i]; //获取本次的盲拍
//             (uint value, bool fake, string calldata secret) = (values[i], fakes[i], secrets[i]);    
//             //在此处添加代码 定义一个变量命名为hashBlindedBid ，将当次历史竞拍信息进行哈希计算

//             console.log("=======value===========", value);
//             //在此处添加代码在控制台输出调试信息 fake ,secret


//             console.logBytes32(bidToCheck.blindedBid);
//             console.logBytes32(hashBlindedBid);
//             //在此处添加代码判断用户传入的当次历史竞拍通过哈希函数计算得到的哈希值和当次盲拍哈希值是否一致，如果不是，则退出当次循环

//             //本次正确披露
//              console.log("========Check pass==========");
//              //在此处添加代码将预存金额累加到返回金额refund

//             //在此处添加代码如果不是伪拍且预存金额大于等于竞拍出价，则调用placeBid函数，判断本次出价是否为最高竞拍价，如果是在返回金额中扣除竞拍价

//             // 使发送者不可能再次认领同一笔订金。
//             bidToCheck.blindedBid = bytes32(0);
//         }          

//         /***************************** end ***************************************************/  
//         payable(msg.sender).transfer(refund);
//         /***************************** begin ***************************************************/
//         // 在此处触发事件SomeOneReveal,告知有人进行了披露操作
         

//         /***************************** end ***************************************************/  
//     }
        
//     // 这是一个 "internal" 函数，
//     // 意味着它只能在本合约（或继承合约）内被调用。
//     function placeBid(address bidder, uint value) internal returns (bool success) {
//         if (value <= highestBid) {
//             return false;
//         }
//         if (highestBidder != address(0)) {
//             // 返还之前的最高出价
//             pendingReturns[highestBidder] += highestBid;
//         }
//         highestBid = value;
//         highestBidder = bidder;
//         return true;
//     }

//     /// 结束拍卖，并把最高的出价发送给受益人。
//     function auctionEnd() external onlyAfter(revealEndTime) {
//         // 对于可与其他合约交互的函数（意味着它会调用其他函数或发送以太币），
//         // 一个好的指导方针是将其结构分为三个阶段：
//         // 1. 检查条件
//         // 2. 执行动作 (可能会改变条件)
//         // 3. 与其他合约交互
//         // 如果这些阶段相混合，其他的合约可能会回调当前合约并修改状态，
//         // 或者导致某些效果（比如支付以太币）多次生效。
//         // 如果合约内调用的函数包含了与外部合约的交互，
//         // 则它也会被认为是与外部合约有交互的。
//         // 1. 条件
//         if (ended)
//             revert AuctionEndAlreadyCalled();
//         // 2. 影响
//         ended = true;
//         // 3. 交互
//         beneficiary.transfer(highestBid);
//         emit AuctionEnded();
//     }
// }