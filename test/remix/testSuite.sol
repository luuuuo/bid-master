// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../BlindAuction.sol";
import "forge-std/console2.sol";

contract testSuite is BlindAuction{

    address acc0 = TestsAccounts.getAccount(0);
    address acc1 = TestsAccounts.getAccount(1);
    address acc2 = TestsAccounts.getAccount(2);
    address acc3 = TestsAccounts.getAccount(3);
    uint256 firstBidBalance = 1 ether;
    uint256 secondBidBalance = 2 ether;
    uint256 thirdBidBalance = 3 ether;

    function beforeAll() public {
        beneficiary = payable(address(acc3));
        init(60, 60, beneficiary);
    }

    // 注意加入payable关键字
    /// #value: 1000000000000000000
    /// #sender: account-1
    function checkAliceFirstBlindBid() public payable{
        bid(keccak256(abi.encode(firstBidBalance, true, "abc")));
        Assert.ok(address(this).balance == firstBidBalance, 'alice first bid should be true');
    }

    /// #value: 2000000000000000000
    /// #sender: account-2
    function checkBobFirstBlindBid() public payable{
        bid(keccak256(abi.encode(secondBidBalance, false, "abc")));
        Assert.ok(address(this).balance == firstBidBalance + secondBidBalance, 'bob first bid should be true');
    }

    /// #value: 3000000000000000000
    /// #sender: account-1
    function checkAliceSecondeBlindBid() public payable{
        bid(keccak256(abi.encode(thirdBidBalance, false, "abc")));
        Assert.ok(address(this).balance == firstBidBalance + secondBidBalance + thirdBidBalance, 'alice second bid should be true');
    }

    /// #sender: account-2
    function checkBobReveal() public payable{
        uint[] memory valuesBob = new uint[](1);
        valuesBob[0] = secondBidBalance;
        bool[] memory fakesBob = new bool[](1);
        fakesBob[0] = false;
        string[] memory secretsBob = new string[](1);
        secretsBob[0] = "abc";
        reveal(valuesBob, fakesBob, secretsBob);
        Assert.ok(address(this).balance == firstBidBalance + secondBidBalance + thirdBidBalance, 'bob reveal first do not retreive money');
    }

    /// #sender: account-1
    function checkAliceReveal() public payable{
        uint[] memory valuesAlice = new uint[](2);
        valuesAlice[0] = firstBidBalance;
        valuesAlice[1] = thirdBidBalance;
        bool[] memory fakesAlice = new bool[](2);
        fakesAlice[0] = true;
        fakesAlice[1] = false;
        string[] memory secretsAlice = new string[](2);
        secretsAlice[0] = "abc";
        secretsAlice[1] = "abc";
        reveal(valuesAlice, fakesAlice, secretsAlice);
        Assert.ok(address(this).balance == secondBidBalance + thirdBidBalance, 'alice reveal first retreive money');
    }

    /// #sender: account-2
    function checkBobWithdraw() public payable{
        uint256 beforeWithdraw = address(acc2).balance;
        withdraw();
        Assert.ok(address(acc2).balance == beforeWithdraw + secondBidBalance, 'bob should retreive money');
    }

    /// #sender: account-2
    function checkAuctionEnd() public payable{
        uint256 beforeAuction = address(beneficiary).balance;
        auctionEnd();
        Assert.ok(address(beneficiary).balance == beforeAuction + thirdBidBalance, 'beneficiary should receive money');
    }
}