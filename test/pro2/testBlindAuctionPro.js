const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { keccak256 } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

// npx hardhat test ./test/pro2/testBlindAuctionPro.js --network localhost
describe("BlindAuctionPro test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [alice, bob] = await ethers.getSigners();
    // 部署盲拍
    const BlindAuctionLib = await ethers.getContractFactory("contracts/pro/pro2/BlindAuctionLib.sol:BlindAuctionLib");
    const blindAuctionLib = await BlindAuctionLib.deploy();
    console.log("blindAuctionLib", blindAuctionLib.address);
    const biddingTime = 60;
    const revealTime = 60;
    const beneficiaryAddress = bob.address;
    const BlindAuctionLogic = await ethers.getContractFactory("contracts/pro/pro2/BlindAuctionLogic.sol:BlindAuctionLogic", {
      libraries: {
        BlindAuctionLib: blindAuctionLib.address,
      },
    });
    const blindAuctionLogic = await BlindAuctionLogic.deploy();
    console.log("blindAuctionLogic", blindAuctionLogic.address);
    const BlindAuction = await ethers.getContractFactory("contracts/pro/pro2/BlindAuction.sol:BlindAuction");
    const blindAuction = await BlindAuction.deploy();
    await blindAuction.upgradeTo(blindAuctionLogic.address);
    await blindAuction.init(biddingTime, revealTime, beneficiaryAddress);
    console.log("owner", await blindAuction.getOwnerAddress())
    return { alice, bob, beneficiaryAddress, blindAuctionLogic, blindAuction };
  }
  
  describe("main flow", function () {
    it("Should Check correct attribute", async function () {
       // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
       const { alice, bob, beneficiaryAddress, blindAuction } = await loadFixture(deployFixture);
       console.log("blindAuction.address", blindAuction.address);
       const bid1 = ethers.utils.keccak256(
         ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther("1.0").toString(), true, "abc"]),
       );
       const bid2 = ethers.utils.keccak256(
         ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther("2.0").toString(), false, "abc"]),
       );
 
       // alice第一次bid
       console.log("alice第一次bid");
       await blindAuction.bid(bid1, {from: alice.address, value: ethers.utils.parseEther("1.0")});
       // 断言合约中余额为 1 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("1.0"));
       console.log("alice第一次bid beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());

       // alice第二次bid
       console.log("alice第二次bid");
       await blindAuction.bid(bid2, {from: alice.address, value: ethers.utils.parseEther("2.0") });
       // 断言合约中余额为 3 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("3.0"));
       console.log("alice第二次bid beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());

       // 披露
       const balanceBeforeReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       const auctionBalanceBeforeReveal = ethers.BigNumber.from(await ethers.provider.getBalance(blindAuction.address));
       await blindAuction.reveal([ethers.utils.parseEther("1.0"), ethers.utils.parseEther("2.0")],[true,false],["abc","abc"], {from: alice.address});
       const balanceAfterReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       const auctionBalanceAfterReveal = ethers.BigNumber.from(await ethers.provider.getBalance(blindAuction.address));
       console.log("披露 beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());

       // 断言合约中余额为 2 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("2.0"));
       console.log("alice reveal前:%s, 后:%s, 退款:%s：", balanceBeforeReveal.toString(), balanceAfterReveal.toString(), balanceAfterReveal.sub(balanceBeforeReveal).abs().toString());
       console.log("blindAuction reveal前:%s, 后:%s", auctionBalanceBeforeReveal.toString(), auctionBalanceAfterReveal.toString());
       console.log("reveal后退款 beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());
       // 断言 alice 余额增加小于 1 ETH（存在gas消耗）
       expect(balanceAfterReveal.sub(balanceBeforeReveal).abs()).to.be.lte(ethers.utils.parseEther("1.0")).to.be.gte(ethers.utils.parseEther("0.999"));

       // 断言结束时收益人余额增加 2 ETH
       const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       const auctionBalanceBeforeEnd = ethers.BigNumber.from(await ethers.provider.getBalance(blindAuction.address));
       await blindAuction.auctionEnd();
       const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       const auctionBalanceAfterEnd = ethers.BigNumber.from(await ethers.provider.getBalance(blindAuction.address));
       console.log("结束bid前后受益人余额：", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
       console.log("blindAuction end前:%s, 后:%s", auctionBalanceBeforeEnd.toString(), auctionBalanceAfterEnd.toString());
       expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther("2.0"));
    });
  });
});
