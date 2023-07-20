const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// npx hardhat test ./test/pro5/testBlindAuctionPro.js --network localhost
describe("BlindAuctionPro test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deployAuctionFactory() {
    const [alice, bob] = await ethers.getSigners();
    // 部署盲拍logic
    console.log("blind auction deploy");
    const BlindAuctionLib = await ethers.getContractFactory("contracts/pro/pro5/libraries/BlindAuctionLib.sol:BlindAuctionLib");
    const blindAuctionLib = await BlindAuctionLib.deploy();
    console.log("blindAuctionLib", blindAuctionLib.address);
    const BlindAuctionLogic = await ethers.getContractFactory("contracts/pro/pro5/logics/BlindAuctionLogic.sol:BlindAuctionLogic", {
      libraries: {
        BlindAuctionLib: blindAuctionLib.address,
      },
    });
    const blindAuctionLogic = await BlindAuctionLogic.deploy();
    console.log("blindAuctionLogic", blindAuctionLogic.address);
    // 部署公开拍卖logic
    // 部署公开拍卖
    console.log("blind auction deploy");
    const OpenAuctionLogic = await ethers.getContractFactory("contracts/pro/pro5/logics/OpenAuctionLogic.sol:OpenAuctionLogic");
    const openAuctionLogic = await OpenAuctionLogic.deploy();
    console.log("openAuctionLogic", openAuctionLogic.address);

    // 部署工厂
    console.log("auction factory deploy");
    const AuctionFactory = await ethers.getContractFactory("contracts/pro/pro5/AuctionFactory.sol:AuctionFactory");
    const auctionFactory = await AuctionFactory.deploy(blindAuctionLogic.address, openAuctionLogic.address);
    console.log("auctionFactory address:", auctionFactory.address);

    // 部署charity慈善合约
    const Charity = await ethers.getContractFactory("contracts/pro/pro5/Charity.sol:Charity");
    const charity = await Charity.deploy();
    console.log("charity address:", charity.address);
    return { auctionFactory, charity };
  }

  async function deployBlindFixture() {
    const [alice, bob] = await ethers.getSigners();
    const biddingTime = 60;
    const revealTime = 60;
    const { auctionFactory, charity } = await loadFixture(deployAuctionFactory);
    await auctionFactory.createAuctions(0);
    const blindAuctionAddress = (await auctionFactory.userAuctions(alice.address, 0)).auctionAddress;
    console.log('=============blindAuctionAddress=============', blindAuctionAddress);
    const blindAuction = await ethers.getContractAt("contracts/pro/pro5/auctions/BlindAuction.sol:BlindAuction", blindAuctionAddress);
    await blindAuction.init(biddingTime, revealTime, charity.address);
    console.log("blindAuction owner address:", await blindAuction.getOwnerAddress());
    return { alice, bob, blindAuction, charity };
  }

  async function deployOpenFixture() {
    const [alice, bob] = await ethers.getSigners();
    const biddingTime = 60;
    const revealTime = 60;
    const { auctionFactory, charity } = await loadFixture(deployAuctionFactory);
    await auctionFactory.createAuctions(1);
    const openAuctionAddress = (await auctionFactory.userAuctions(alice.address, 0)).auctionAddress;
    console.log('=============openAuctionAddress=============', openAuctionAddress);
    const openAuction = await ethers.getContractAt("contracts/pro/pro5/auctions/OpenAuction.sol:OpenAuction", openAuctionAddress);
    await openAuction.init(biddingTime, charity.address);
    return { alice, bob, openAuction, charity };
  }

  describe("main flow", function () {
    it("Check open auction", async function () {
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, openAuctionLogic, openAuction, charity } = await loadFixture(deployOpenFixture);
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
    });

    it("Check blind auction", async function () {
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, blindAuction, charity } = await loadFixture(deployBlindFixture);
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
      const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      await blindAuction.auctionEnd();
      const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther("2.0"));
      console.log(await charity.donations(0));
      expect((await charity.donations(0)).donor).to.be.eq(blindAuction.address);
      expect((await charity.donations(0)).amount).to.be.eq(ethers.utils.parseEther("2.0"));
    });
  });
});
