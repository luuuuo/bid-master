const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// npx hardhat test ./test/pro3/testBlindAuctionPro.js --network localhost
describe("BlindAuctionPro test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployBlindFixture() {
    const [alice, bob] = await ethers.getSigners();
    // 部署盲拍
    console.log("blind auction deploy");
    const BlindAuctionLib = await ethers.getContractFactory("contracts/pro/pro3/libraries/BlindAuctionLib.sol:BlindAuctionLib");
    const blindAuctionLib = await BlindAuctionLib.deploy();
    console.log("blindAuctionLib", blindAuctionLib.address);
    const biddingTime = 60;
    const revealTime = 60;
    const beneficiaryAddress = bob.address;
    const BlindAuctionLogic = await ethers.getContractFactory("contracts/pro/pro3/logics/BlindAuctionLogic.sol:BlindAuctionLogic", {
      libraries: {
        BlindAuctionLib: blindAuctionLib.address,
      },
    });
    const blindAuctionLogic = await BlindAuctionLogic.deploy();
    console.log("blindAuctionLogic", blindAuctionLogic.address);
    const BlindAuction = await ethers.getContractFactory("contracts/pro/pro3/auctions/BlindAuction.sol:BlindAuction");
    const blindAuction = await BlindAuction.deploy();
    console.log("blindAuction owner address:", await blindAuction.getOwnerAddress());
    await blindAuction.init(biddingTime, revealTime, beneficiaryAddress);
    console.log("blindAuction owner address:", await blindAuction.getOwnerAddress());
    await blindAuction.upgradeTo(blindAuctionLogic.address);
    return { alice, bob, beneficiaryAddress, blindAuctionLogic, blindAuction };
  }

  async function deployOpenFixture() {
    const [alice, bob] = await ethers.getSigners();
    const biddingTime = 60;
    const beneficiaryAddress = bob.address;
    // 部署公开拍卖
    console.log("blind auction deploy");
    const OpenAuctionLogic = await ethers.getContractFactory("contracts/pro/pro3/logics/OpenAuctionLogic.sol:OpenAuctionLogic");
    const openAuctionLogic = await OpenAuctionLogic.deploy();
    console.log("openAuctionLogic", openAuctionLogic.address);
    const OpenAuction = await ethers.getContractFactory("contracts/pro/pro3/auctions/OpenAuction.sol:OpenAuction");
    const openAuction = await OpenAuction.deploy();
    await openAuction.init(biddingTime, beneficiaryAddress);
    await openAuction.upgradeTo(openAuctionLogic.address);
    return { alice, bob, beneficiaryAddress, openAuctionLogic, openAuction };
  }

  describe("main flow", function () {
    it("Check open auction", async function () {
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, beneficiaryAddress, openAuctionLogic, openAuction } = await loadFixture(deployOpenFixture);
      // alice第一次bid
      // https://hardhat.org/tutorial/testing-contracts#using-a-different-account
      await openAuction.bid({from: alice.address, value: ethers.utils.parseEther("1.0")});
      // await openAuction.connect(alice).bid({value: ethers.utils.parseEther("1.0")});
      // 断言合约中余额为 1 ETH
      expect(await ethers.provider.getBalance(openAuction.address)).to.equal(ethers.utils.parseEther("1.0"));
      // alice第二次bid
      await openAuction.bid({from: alice.address, value: ethers.utils.parseEther("2.0")});
      // await openAuction.connect(bob).bid({value: ethers.utils.parseEther("2.0")});
      const balanceBeforeWithdraw = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
      await openAuction.withdraw({from: alice.address});
      expect(await ethers.provider.getBalance(openAuction.address)).to.equal(ethers.utils.parseEther("2.0"));
      const balanceAfterWithdraw = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       // 断言 alice 余额增加小于 1 ETH（存在gas消耗）
       console.log("refund amount:", balanceAfterWithdraw.sub(balanceBeforeWithdraw).abs());
       expect(balanceAfterWithdraw.sub(balanceBeforeWithdraw).abs()).to.be.lt(ethers.utils.parseEther("1.0")).to.be.gt(ethers.utils.parseEther("0.999"));

       // 断言结束时收益人余额增加 2 ETH
       const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       await openAuction.auctionEnd();
       const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       console.log("open auction结束bid前后受益人余额：", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
       expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther("2.0"));
    });

    it("Check blind auction", async function () {
       // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
       const { alice, bob, beneficiaryAddress, blindAuction } = await loadFixture(deployBlindFixture);
       console.log("blindAuction.address", blindAuction.address);
       const bid1 = ethers.utils.keccak256(
         ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther("1.0").toString(), true, "abc"]),
       );
       const bid2 = ethers.utils.keccak256(
         ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther("2.0").toString(), false, "abc"]),
       );
 
       // alice第一次bid
       await blindAuction.bid(bid1, {from: alice.address, value: ethers.utils.parseEther("1.0")});
       // 断言合约中余额为 1 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("1.0"));
 
       // alice第二次bid
       await blindAuction.bid(bid2, {from: alice.address, value: ethers.utils.parseEther("2.0") });
       // 断言合约中余额为 3 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("3.0"));
 
       // 披露
       const balanceBeforeReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       await blindAuction.reveal([ethers.utils.parseEther("1.0"), ethers.utils.parseEther("2.0")],[true,false],["abc","abc"], {from: alice.address});
       const balanceAfterReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       // 断言合约中余额为 2 ETH
       expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther("2.0"));
       // 断言 alice 余额增加小于 1 ETH（存在gas消耗）
       console.log("after reveal refund：", balanceAfterReveal.sub(balanceBeforeReveal).abs());
       expect(balanceAfterReveal.sub(balanceBeforeReveal).abs()).to.be.lt(ethers.utils.parseEther("1.0")).to.be.gt(ethers.utils.parseEther("0.999"));

       // 断言结束时收益人余额增加 2 ETH
       const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       await blindAuction.auctionEnd();
       const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
       console.log("blind auction结束bid前后受益人余额：", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
       expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther("2.0"));
    });
  });
});
