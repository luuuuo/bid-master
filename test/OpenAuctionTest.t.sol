// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {OpenAuctionLogic} from "../src/contracts/pro/pro6/logics/OpenAuctionLogic.sol";
import {OpenAuction} from "../src/contracts/pro/pro6/auctions/OpenAuction.sol";
import {OpenAuctionInterface} from "../src/contracts/pro/pro6/interfaces/OpenAuctionInterface.sol";
import {AuctionErrors} from "../src/contracts/pro/pro6/errors/AuctionErrors.sol";
import {OpenAuctionLogic} from "../src/contracts/pro/pro6/logics/OpenAuctionLogic.sol";
import {AuctionFactory} from "../src/contracts/pro/pro6/AuctionFactory.sol";
import {Charity} from "../src/contracts/pro/pro6/Charity.sol";
import {BidMasterPoint} from "../src/contracts/pro/pro6/ERC20/BidMasterPoint.sol";
import {MyApe} from "../src/contracts/pro/pro6/ERC721/MyApe.sol";
import "forge-std/console2.sol";
import {Utilities} from "./utils/Utilities.sol";

// forge test --match-contract OpenAuctionTest -vv
contract OpenAuctionTest is Test {
    BidMasterPoint public bidMasterPoint;
    MyApe public myApe;
    OpenAuctionInterface public openAuction;
    OpenAuctionLogic public openAuctionLogic;
    AuctionFactory public auctionFactory;
    Charity public charity;
    // 需要注明该地址可以接受 ETH
    address payable public bob;
    address payable public alice;
    Utilities internal utils;
    address payable[] internal users;

    function setUp() public {
        bidMasterPoint = new BidMasterPoint("nl","nl");
        myApe = new MyApe("nle","nle");
        openAuctionLogic = new OpenAuctionLogic();
        auctionFactory = new AuctionFactory(address(0), address(openAuctionLogic));
        charity = new Charity();
        utils = new Utilities();
        users = utils.createUsers(5);
        bob = users[0];
        alice = users[1];
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }

    function testOpenAuction() public {
        uint tokenId = 0;
        uint256 biddingTime = 60;
        uint256 firstBidBalance = 1 ether;
        uint256 secondBidBalance = 2 ether;
        uint256 thirdBidBalance = 3 ether;
        console2.log("========================auction bid deadtime:%s========================", block.timestamp + biddingTime);
        // 创建盲拍NFT并授权给盲拍合约
        openAuction = OpenAuctionInterface(auctionFactory.createAuctions(AuctionFactory.AuctionType.Open));
        console2.log("OpenAuction address:%s", address(openAuction));
        openAuction.init(biddingTime, payable(address(charity)), address(bidMasterPoint), address(myApe), tokenId);
        myApe.mint(address(this), tokenId);
        myApe.approve(address(openAuction), tokenId);
        console2.log("========================current time:%s========================", block.timestamp);
        // alice第一次bid
        uint256 beforeFirstBidBalance = address(openAuction).balance;
        // 对于中文注解需要转义成unicode，此注释为“alice第一次bid”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("alice\u7b2c\u4e00\u6b21bid");
        vm.startPrank(alice);
        openAuction.bid{value: firstBidBalance}();
        vm.stopPrank();
        assertEq(address(openAuction).balance - beforeFirstBidBalance, firstBidBalance);

        // bob发现有人用发起竞拍，于是他加价竞拍
        uint256 beforeSecondBidBalance = address(openAuction).balance;
        // 对于中文注解需要转义成unicode，此注释为“bob第一次bid”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("bob\u7b2c\u4e00\u6b21bid");
        vm.startPrank(bob);
        openAuction.bid{value: secondBidBalance}();
        vm.stopPrank();
        assertEq(address(openAuction).balance - beforeSecondBidBalance, secondBidBalance);

        uint256 beforeThirdBidBalance = address(openAuction).balance;
        // alice 发现有人加价竞拍，她最后加价
        // 对于中文注解需要转义成unicode，此注释为“alice第二次bid”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("alice\u7b2c\u4e8c\u6b21bid");
        vm.startPrank(alice);
        openAuction.bid{value: thirdBidBalance}();
        vm.stopPrank();
        assertEq(address(openAuction).balance - beforeThirdBidBalance, thirdBidBalance);
        console2.log("========================current time:%s========================", block.timestamp);
        vm.warp(block.timestamp + biddingTime);
        console2.log("========================current time:%s========================", block.timestamp);
        // 竞拍结束，期望在竞拍结束后无法再继续出价bid
        vm.expectRevert("delegatecall failed");
        vm.startPrank(bob);
        openAuction.bid{value: thirdBidBalance + 1 ether}();
        vm.stopPrank();
        // 此处bob竞拍失败，提供withdraw方法取回拍卖资金
        // bob 取钱
        vm.startPrank(bob);
        uint256 beforeWithdrawBob = bob.balance;
        openAuction.withdraw();
        console2.log("bob auction failed, deposit:%s, withdraw balance:%s", secondBidBalance, bob.balance - beforeWithdrawBob);
        assertEq(bob.balance - beforeWithdrawBob, secondBidBalance);
        vm.stopPrank();

        // 校验慈善组织余额
        uint256 beforeAuctionBalance = address(charity).balance;
        // 披露结束，在披露结束后无法再继续披露reveal
        vm.warp(block.timestamp + 1);
        openAuction.auctionEnd();
        console2.log("charity beforeAuctionBalance:%s, afterAuctionBalance:%s", beforeAuctionBalance, address(charity).balance);
        assertEq(address(charity).balance - beforeAuctionBalance, thirdBidBalance);
        // 校验NFT归属
        address ownerAddress = myApe.ownerOf(tokenId);
        assertEq(ownerAddress, alice);
        // 校验积分情况
        uint256 pointAlice = bidMasterPoint.balanceOf(alice);
        uint256 pointBob = bidMasterPoint.balanceOf(bob);
        console2.log("pointAlice:%s, pointBob:%s", pointAlice, pointBob);
        assertEq(pointAlice, 10);
        assertEq(pointBob, 10);
    }
}