const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { keccak256 } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

// npx hardhat test ./test/pro1/testBlindAuctionPro.js --network localhost
describe("BlindAuctionPro test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [alice, bob] = await ethers.getSigners();
    // 部署
    const BlindAuctionLib = await ethers.getContractFactory("contracts/pro/pro_1/BlindAuctionLib.sol:BlindAuctionLib");
    const blindAuctionLib = await BlindAuctionLib.deploy();
    console.log(blindAuctionLib.address);
    const biddingTime = 60;
    const revealTime = 60;
    const beneficiaryAddress = bob.address;
    const BlindAuction = await ethers.getContractFactory("contracts/pro/pro_1/BlindAuction.sol:BlindAuction", {
      libraries: {
        BlindAuctionLib: blindAuctionLib.address,
      },
    });
    const blindAuction = await BlindAuction.deploy(biddingTime, revealTime, beneficiaryAddress);
    return { alice, bob, beneficiaryAddress, blindAuction };
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
      console.log("alice 初始 EtherBalance:", await ethers.provider.getBalance(alice.address));

      // alice第一次bid
      console.log("alice第一次bid");
      console.log(bid1);
      await blindAuction.connect(alice).bid(bid1, { value: ethers.utils.parseEther("1.0") });
      console.log(await blindAuction.bids(alice.address, 0));
      console.log("alice第一次bid EtherBalance:", await ethers.provider.getBalance(alice.address));

      // alice第二次bid
      console.log("alice第二次bid");
      console.log(bid2);
      await blindAuction.connect(alice).bid(bid2, { value: ethers.utils.parseEther("2.0") });
      console.log(await blindAuction.bids(alice.address, 1));
      console.log("alice第二次bid EtherBalance:", await ethers.provider.getBalance(alice.address));
      // 披露
      console.log("alice before reveal EtherBalance:", await ethers.provider.getBalance(alice.address));
      await blindAuction.connect(alice).reveal([ethers.utils.parseEther("1.0"), ethers.utils.parseEther("2.0")],[true,false],["abc","abc"]);
      console.log("alice after reveal EtherBalance:", await ethers.provider.getBalance(alice.address));
    });
  });
});
