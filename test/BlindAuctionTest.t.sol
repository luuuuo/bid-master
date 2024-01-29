// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";
import {BlindAuctionLib} from "../src/contracts/pro/pro6/libraries/BlindAuctionLib.sol";
import {BlindAuctionLogic} from "../src/contracts/pro/pro6/logics/BlindAuctionLogic.sol";
import {BlindAuction} from "../src/contracts/pro/pro6/auctions/BlindAuction.sol";
import {BlindAuctionInterface} from "../src/contracts/pro/pro6/interfaces/BlindAuctionInterface.sol";
import {AuctionErrors} from "../src/contracts/pro/pro6/errors/AuctionErrors.sol";
import {AuctionFactory} from "../src/contracts/pro/pro6/AuctionFactory.sol";
import {Charity} from "../src/contracts/pro/pro6/Charity.sol";
import {BidMasterPoint} from "../src/contracts/pro/pro6/ERC20/BidMasterPoint.sol";
import {MyApe} from "../src/contracts/pro/pro6/ERC721/MyApe.sol";
import "forge-std/console2.sol";
import {Utilities} from "./utils/Utilities.sol";

// forge test --match-contract BlindAuctionTest -vv
contract BlindAuctionTest is Test {
    BidMasterPoint public bidMasterPoint;
    MyApe public myApe;
    BlindAuctionInterface public blindAuction;
    BlindAuctionLogic public blindAuctionLogic;
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
        blindAuctionLogic = new BlindAuctionLogic();
        auctionFactory = new AuctionFactory(address(blindAuctionLogic), address(0));
        charity = new Charity();
        utils = new Utilities();
        users = utils.createUsers(5);
        bob = users[0];
        alice = users[1];
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
    }

    function testBlindAuction() public {
        uint tokenId = 0;
        uint256 biddingTime = 60;
        uint256 revealTime = 60;
        uint256 firstBidBalance = 1 ether;
        uint256 secondBidBalance = 2 ether;
        uint256 thirdBidBalance = 3 ether;
        console2.log("========================auction bid deadtime:%s, auction reveal deadtime:%s========================", block.timestamp + biddingTime, block.timestamp + biddingTime + revealTime);
        // 创建盲拍NFT并授权给盲拍合约
        blindAuction = BlindAuctionInterface(auctionFactory.createAuctions(AuctionFactory.AuctionType.Blind));
        console2.log("blindAuction address:%s", address(blindAuction));
        blindAuction.init(biddingTime, revealTime, payable(address(charity)), address(bidMasterPoint), address(myApe), tokenId);
        myApe.mint(address(this), tokenId);
        myApe.approve(address(blindAuction), tokenId);
        console2.log("========================current time:%s========================", block.timestamp);
        // alice第一次bid
        uint256 beforeFirstBidBalance = address(blindAuction).balance;
        bytes32 bidHash1 = keccak256(abi.encode(firstBidBalance, true, "abc"));
        // 对于中文注解需要转义成unicode，此注释为“alice第一次bid，hash”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("alice\u7b2c\u4e00\u6b21bid\uff0chash");
        console2.logBytes32(bidHash1);
        vm.startPrank(alice);
        blindAuction.bid{value: firstBidBalance}(bidHash1);
        vm.stopPrank();
        assertEq(address(blindAuction).balance - beforeFirstBidBalance, firstBidBalance);

        // bob发现有人用发起竞拍，于是他加价竞拍
        uint256 beforeSecondBidBalance = address(blindAuction).balance;
        bytes32 bidHash2 = keccak256(abi.encode(secondBidBalance, false, "abc"));
        // 对于中文注解需要转义成unicode，此注释为“bob第一次bid，hash”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("bob\u7b2c\u4e00\u6b21bid\uff0chash");
        console2.logBytes32(bidHash2);
        vm.startPrank(bob);
        blindAuction.bid{value: secondBidBalance}(bidHash2);
        vm.stopPrank();
        assertEq(address(blindAuction).balance - beforeSecondBidBalance, secondBidBalance);

        uint256 beforeThirdBidBalance = address(blindAuction).balance;
        bytes32 bidHash3 = keccak256(abi.encode(thirdBidBalance, false, "abc"));
        // alice 发现有人加价竞拍，她最后加价
        // 对于中文注解需要转义成unicode，此注释为“alice第二次bid，hash”，在线转换工具：https://www.jyshare.com/front-end/3602/
        console2.log("alice\u7b2c\u4e8c\u6b21bid\uff0chash");
        console2.logBytes32(bidHash3);
        vm.startPrank(alice);
        blindAuction.bid{value: thirdBidBalance}(bidHash3);
        vm.stopPrank();
        assertEq(address(blindAuction).balance - beforeThirdBidBalance, thirdBidBalance);
        console2.log("========================current time:%s========================", block.timestamp);
        vm.warp(block.timestamp + biddingTime);
        console2.log("========================current time:%s========================", block.timestamp);
        // 竞拍结束，期望在竞拍结束后无法再继续出价bid
        bytes32 bidHash4 = keccak256(abi.encode(thirdBidBalance + 1 ether, false, "abc"));
        vm.expectRevert("delegatecall failed");
        vm.startPrank(bob);
        blindAuction.bid{value: thirdBidBalance + 1 ether}(bidHash4);
        vm.stopPrank();
        vm.warp(block.timestamp + 1);
        // bob 披露
        vm.startPrank(bob);
        uint[] memory valuesBob = new uint[](1);
        valuesBob[0] = secondBidBalance;
        bool[] memory fakesBob = new bool[](1);
        fakesBob[0] = false;
        string[] memory secretsBob = new string[](1);
        secretsBob[0] = "abc";
        blindAuction.reveal(valuesBob, fakesBob, secretsBob);
        vm.stopPrank();

        // alice 披露
        vm.startPrank(alice);
        uint[] memory valuesAlice = new uint[](2);
        valuesAlice[0] = firstBidBalance;
        valuesAlice[1] = thirdBidBalance;
        bool[] memory fakesAlice = new bool[](2);
        fakesAlice[0] = true;
        fakesAlice[1] = false;
        string[] memory secretsAlice = new string[](2);
        secretsAlice[0] = "abc";
        secretsAlice[1] = "abc";
        blindAuction.reveal(valuesAlice, fakesAlice, secretsAlice);
        vm.stopPrank();
        // 此处bob竞拍失败，提供withdraw方法取回拍卖资金
        
        // bob 取钱
        vm.startPrank(bob);
        uint256 beforeWithdrawBob = bob.balance;
        blindAuction.withdraw();
        console2.log("bob auction failed, deposit:%s, withdraw balance:%s", secondBidBalance, bob.balance - beforeWithdrawBob);
        assertEq(bob.balance - beforeWithdrawBob, secondBidBalance);
        vm.stopPrank();

        // 校验慈善组织余额
        uint256 beforeAuctionBalance = address(charity).balance;
        // 披露结束，在披露结束后无法再继续披露reveal
        vm.warp(block.timestamp + revealTime);
        blindAuction.auctionEnd();
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