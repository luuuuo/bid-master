const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { keccak256 } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

// npx hardhat test ./test/testBlindAuction.js
describe("Ed3LoyaltyPoints test", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    const [alice, bob] = await ethers.getSigners();
    // 部署
    const biddingTime = 60;
    const revealTime = 60;
    const beneficiaryAddress = alice.address;
    const BlindAuction = await ethers.getContractFactory("BlindAuction");
    const blindAuction = await BlindAuction.deploy(biddingTime, revealTime, beneficiaryAddress);
    return { alice, bob, beneficiaryAddress, blindAuction };
  }

  describe("Deployment", function () {
    it("Should Check correct attribute", async function () {
      // loadFixture will run the setup the first time, and quickly return to that state in the other tests.
      const { alice, bob, beneficiaryAddress, blindAuction } = await loadFixture(deployFixture);
      console.log("blindAuction.address", blindAuction.address);

      const bid1 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [1, true, "abc"]),
      );
      const bid2 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [2, false, "abc"]),
      );
      const bobbid1 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [3, true, "abc"]),
      );
      const bobbid2 = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["uint256", "bool", "string"], [4, false, "abc"]),
      );
      // alice第一次bid
      console.log("alice第一次bid");
      console.log(bid1);
      await blindAuction.connect(alice).bid(bid1, { value: 1 });
      console.log(await blindAuction.bids(alice.address, 0));
      // alice第二次bid
      console.log("alice第二次bid");
      console.log(bid2);
      await blindAuction.connect(alice).bid(bid2, { value: 2 });
      console.log(await blindAuction.bids(alice.address, 1));

      // bob第一次bid
      console.log("bob第一次bid");
      console.log(bobbid1);
      await blindAuction.connect(bob).bid(bobbid1, { value: 3 });
      console.log(await blindAuction.bids(bob.address, 0));
      // bob第二次bid
      console.log("bob第二次bid");

      console.log(bobbid2);
      await blindAuction.connect(bob).bid(bobbid2, { value: 4 });
      console.log(await blindAuction.bids(bob.address, 1));

      // 披露
      await blindAuction
        .connect(alice)
        .reveal([1, 2, 3, 4], [true, false, true, false], [bid1, bid2, bobbid1, bobbid2]);
    });
  });
});
