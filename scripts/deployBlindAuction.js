// npx hardhat run ./scripts/deployBlindAuction.js  --network PolygonMumbai
// npx hardhat run ./scripts/deployBlindAuction.js  --network localhost
const hre = require("hardhat");
const { ethers } = require("hardhat");
const moment = require("moment");

async function main() {
  const [alice, bob] = await ethers.getSigners();

  // 部署
  const biddingTime = 60;
  const revealTime = 60;
  const beneficiaryAddress = alice.address;
  const BlindAuction = await ethers.getContractFactory("BlindAuction");
  const blindAuction = await BlindAuction.deploy(biddingTime, revealTime, beneficiaryAddress);
  console.log(
    `npx hardhat verify --network PolygonMumbai "${blindAuction.address}" ${biddingTime} ${revealTime} ${beneficiaryAddress}`,
  );

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
  console.log("alice第一次bid", bid1);
  await blindAuction.connect(alice).bid(bid1, { value: 1 });
  // alice第二次bid
  console.log("alice第二次bid", bid2);
  await blindAuction.connect(alice).bid(bid2, { value: 2 });

  // bob第一次bid
  console.log("bob第一次bid", bobbid1);
  await blindAuction.connect(bob).bid(bobbid1, { value: 3 });
  // bob第二次bid
  console.log("bob第二次bid", bobbid2);
  await blindAuction.connect(bob).bid(bobbid2, { value: 4 });

  // 披露
  await blindAuction.connect(alice).reveal([1, 2], [true, false], ["abc", "abc"]);
  console.log("====================reveal");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
