const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// npx hardhat test ./test/pro6/testBlindAuctionPro.js --network localhost
describe("BlindAuctionPro test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deployAuctionFactory() {
    const [alice, bob] = await ethers.getSigners();
    // 部署积分合约
    const BidMasterPoint = await ethers.getContractFactory("contracts/pro/pro6/ERC20/BidMasterPoint.sol:BidMasterPoint");
    const bidMasterPoint = await BidMasterPoint.deploy("nl","nl");
    // 部署NFT合约
    const MyApe = await ethers.getContractFactory("contracts/pro/pro6/ERC721/MyApe.sol:MyApe");
    const myApe = await MyApe.deploy("nle","nle");

    // 部署盲拍logic
    console.log("blind auction deploy");
    const BlindAuctionLib = await ethers.getContractFactory("contracts/pro/pro6/libraries/BlindAuctionLib.sol:BlindAuctionLib");
    const blindAuctionLib = await BlindAuctionLib.deploy();
    console.log("blindAuctionLib", blindAuctionLib.address);
    const BlindAuctionLogic = await ethers.getContractFactory("contracts/pro/pro6/logics/BlindAuctionLogic.sol:BlindAuctionLogic", {
      libraries: {
        BlindAuctionLib: blindAuctionLib.address,
      },
    });
    const blindAuctionLogic = await BlindAuctionLogic.deploy();
    console.log("blindAuctionLogic", blindAuctionLogic.address);
    // 部署公开拍卖logic
    // 部署公开拍卖
    console.log("blind auction deploy");
    const OpenAuctionLogic = await ethers.getContractFactory("contracts/pro/pro6/logics/OpenAuctionLogic.sol:OpenAuctionLogic");
    const openAuctionLogic = await OpenAuctionLogic.deploy();
    console.log("openAuctionLogic", openAuctionLogic.address);

    // 部署工厂
    console.log("auction factory deploy");
    const AuctionFactory = await ethers.getContractFactory("contracts/pro/pro6/AuctionFactory.sol:AuctionFactory");
    const auctionFactory = await AuctionFactory.deploy(blindAuctionLogic.address, openAuctionLogic.address);
    console.log("auctionFactory address:", auctionFactory.address);

    // 部署charity慈善合约
    const Charity = await ethers.getContractFactory("contracts/pro/pro6/Charity.sol:Charity");
    const charity = await Charity.deploy();
    console.log("charity address:", charity.address);
    return { bidMasterPoint, myApe, auctionFactory, charity };
  }

  async function deployBlindFixture() {
    const [alice, bob] = await ethers.getSigners();
    const biddingTime = 60;
    const revealTime = 60;
    const { bidMasterPoint, myApe, auctionFactory, charity } = await loadFixture(deployAuctionFactory);
    await auctionFactory.createAuctions(0);
    const blindAuctionAddress = (await auctionFactory.userAuctions(alice.address, 0)).auctionAddress;
    console.log('=============blindAuctionAddress=============', blindAuctionAddress);
    const blindAuction = await ethers.getContractAt("contracts/pro/pro6/auctions/BlindAuction.sol:BlindAuction", blindAuctionAddress);
    await myApe.mint(alice.address, 0);
    await myApe.approve(blindAuction.address, 0);
    await blindAuction.init(biddingTime, revealTime, charity.address, bidMasterPoint.address, myApe.address, 0);
    console.log("blindAuction owner address:", await blindAuction.getOwnerAddress());
    return { alice, bob, blindAuction, charity, bidMasterPoint, myApe };
  }

  async function deployOpenFixture() {
    const [alice, bob] = await ethers.getSigners();
    const biddingTime = 60;
    const revealTime = 60;
    const { bidMasterPoint, myApe, auctionFactory, charity } = await loadFixture(deployAuctionFactory);
    await auctionFactory.createAuctions(1);
    const openAuctionAddress = (await auctionFactory.userAuctions(alice.address, 0)).auctionAddress;
    console.log('=============openAuctionAddress=============', openAuctionAddress);
    const openAuction = await ethers.getContractAt("contracts/pro/pro6/auctions/OpenAuction.sol:OpenAuction", openAuctionAddress);
    await myApe.mint(alice.address, 1);
    await myApe.approve(openAuction.address, 1);
    await openAuction.init(biddingTime, charity.address, bidMasterPoint.address, myApe.address, 1);
    return { alice, bob, openAuction, charity, bidMasterPoint, myApe };
  }

  describe("main flow", function () {
    it("Check open auction", async function () {
      const firstBidBalance = "1.0";
      const secondBidBalance = "1.5";
      const thirdBidBalance = "2.0";
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, openAuction, charity, bidMasterPoint, myApe } = await loadFixture(deployOpenFixture);
      // alice第一次bid
      // https://hardhat.org/tutorial/testing-contracts#using-a-different-account
      // await openAuction.bid({from: alice.address, value: ethers.utils.parseEther(firstBidBalance)});
      await openAuction.connect(alice).bid({value: ethers.utils.parseEther(firstBidBalance)});
      console.log("alice第一次bid");
      // 断言合约中余额为 1 ETH
      expect(await ethers.provider.getBalance(openAuction.address)).to.equal(ethers.utils.parseEther(firstBidBalance));
      // bob第一次bid
      await openAuction.connect(bob).bid({value: ethers.utils.parseEther(secondBidBalance)});
      console.log("bob第一次bid");
      // alice第二次bid
      await openAuction.connect(alice).bid({value: ethers.utils.parseEther(thirdBidBalance)});
      console.log("alice第二次bid");
      // 断言合约中余额
      expect(await ethers.provider.getBalance(openAuction.address)).to.equal(ethers.utils.parseEther(firstBidBalance).add(ethers.utils.parseEther(secondBidBalance)).add(ethers.utils.parseEther(thirdBidBalance)));
      const balanceBeforeWithdraw = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));

      await openAuction.connect(alice).withdraw();
      await openAuction.connect(bob).withdraw();

      expect(await ethers.provider.getBalance(openAuction.address)).to.equal(ethers.utils.parseEther(thirdBidBalance));
      const balanceAfterWithdraw = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
       // 断言 alice 余额增加小于 1 ETH（存在gas消耗）
      console.log("refund amount:", balanceAfterWithdraw.sub(balanceBeforeWithdraw).abs());
      expect(balanceAfterWithdraw.sub(balanceBeforeWithdraw).abs()).to.be.lt(ethers.utils.parseEther(firstBidBalance)).to.be.gt(ethers.utils.parseEther("0.999"));

      // 断言结束时收益人余额增加 2 ETH，竞拍获胜者获得NFT，所有参与者获得积分
      const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      await openAuction.auctionEnd();
      console.log("auction end successfully");
      const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      console.log("open auction结束bid前后受益人余额：%s, %s", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
      expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther(thirdBidBalance));
      console.log("open auction结束后charity余额：", await charity.donations(0));
      expect((await charity.donations(0)).donor).to.be.eq(openAuction.address);
      expect((await charity.donations(0)).amount).to.be.eq(ethers.utils.parseEther(thirdBidBalance));
      console.log("open auction结束后NFT归属：", await myApe.ownerOf(1));
      expect(await myApe.ownerOf(1)).to.be.eq(alice.address);
      console.log("open auction结束后 alice 积分数量：", await bidMasterPoint.balanceOf(alice.address));
      console.log("open auction结束后 bob 积分数量：", await bidMasterPoint.balanceOf(bob.address));
      expect(await bidMasterPoint.balanceOf(alice.address)).to.be.eq(10);
      expect(await bidMasterPoint.balanceOf(bob.address)).to.be.eq(10);
    });

    it("Check blind auction", async function () {
      const firstBidBalance = "1.0";
      const secondBidBalance = "1.5";
      const thirdBidBalance = "2.0";
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, blindAuction, charity, bidMasterPoint, myApe } = await loadFixture(deployBlindFixture);
      console.log("blindAuction.address", blindAuction.address);
      const bid1 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther(firstBidBalance).toString(), true, "abc"]),
      );
      // alice第一次bid
      await blindAuction.connect(alice).bid(bid1, {value: ethers.utils.parseEther(firstBidBalance)});
      // 断言合约中余额为 1 ETH
      expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther(firstBidBalance));

      // bob发现有人用1ETH发起竞拍，于是他发起1.5ETH竞拍
      const bid2 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther(secondBidBalance).toString(), false, "abc"]),
      );
      // bob第一次bid
      await blindAuction.connect(bob).bid(bid2, {value: ethers.utils.parseEther(secondBidBalance)});


      // alic发现有人用1.5ETH发起竞拍，于是他发起2ETH竞拍
      const bid3 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [ethers.utils.parseEther(thirdBidBalance).toString(), false, "abc"]),
      );
      // alice第二次bid
      await blindAuction.connect(alice).bid(bid3, {value: ethers.utils.parseEther(thirdBidBalance) });
      // 断言合约中余额
      expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther(firstBidBalance).add(ethers.utils.parseEther(secondBidBalance)).add(ethers.utils.parseEther(thirdBidBalance)));

      console.log("finish bid");

      // 披露
      const balanceBeforeReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
      await blindAuction.connect(alice).reveal([ethers.utils.parseEther(firstBidBalance), ethers.utils.parseEther(thirdBidBalance)],[true,false],["abc","abc"]);
      const balanceAfterReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
      await blindAuction.connect(bob).reveal([ethers.utils.parseEther(secondBidBalance)],[false],["abc"]);

      console.log("finish reveal");

      // 断言合约中余额为 2 ETH
      expect(await ethers.provider.getBalance(blindAuction.address)).to.equal(ethers.utils.parseEther(thirdBidBalance));
      // 断言 alice 余额增加小于 1 ETH（存在gas消耗）
      console.log("after reveal refund：", balanceAfterReveal.sub(balanceBeforeReveal).abs());
      expect(balanceAfterReveal.sub(balanceBeforeReveal).abs()).to.be.lt(ethers.utils.parseEther(firstBidBalance)).to.be.gt(ethers.utils.parseEther("0.999"));

      // 断言结束时收益人余额增加 2 ETH
      const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      await blindAuction.auctionEnd();
      const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(charity.address));
      console.log("blind auction结束bid前后受益人余额：", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
      expect(balanceAfterEndAuction.sub(balanceBeforeEndAuction).abs()).to.be.eq(ethers.utils.parseEther(thirdBidBalance));
      console.log("blind auction结束后charity余额：", await charity.donations(0));
      expect((await charity.donations(0)).donor).to.be.eq(blindAuction.address);
      expect((await charity.donations(0)).amount).to.be.eq(ethers.utils.parseEther(thirdBidBalance));

      console.log("blind auction结束后NFT归属：", await myApe.ownerOf(0));
      expect(await myApe.ownerOf(0)).to.be.eq(alice.address);
      console.log("blind auction结束后 alice 积分数量：", await bidMasterPoint.balanceOf(alice.address));
      console.log("blind auction结束后 bob 积分数量：", await bidMasterPoint.balanceOf(bob.address));
      expect(await bidMasterPoint.balanceOf(alice.address)).to.be.eq(10);
      expect(await bidMasterPoint.balanceOf(bob.address)).to.be.eq(10);
    });
  });
});
