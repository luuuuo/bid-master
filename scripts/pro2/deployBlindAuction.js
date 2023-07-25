// npx hardhat run ./scripts/pro2/deployBlindAuction.js  --network tenderly
// npx hardhat run ./scripts/pro2/deployBlindAuction.js  --network localhost
const hre = require("hardhat");
const { ethers } = require("hardhat");
const moment = require("moment");

async function main() {
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
  await blindAuction.init(biddingTime, revealTime, beneficiaryAddress);
  await blindAuction.upgradeTo(blindAuctionLogic.address);
  console.log("owner", await blindAuction.getOwnerAddress())
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
  console.log("alice第一次bid beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());

  // alice第二次bid
  console.log("alice第二次bid");
  await blindAuction.bid(bid2, {from: alice.address, value: ethers.utils.parseEther("2.0") });
  // 断言合约中余额为 3 ETH
  console.log("alice第二次bid beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());

  // 披露
  const balanceBeforeReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
  await blindAuction.reveal([ethers.utils.parseEther("1.0"), ethers.utils.parseEther("2.0")],[true,false],["abc","abc"], {from: alice.address});
  const balanceAfterReveal = ethers.BigNumber.from(await ethers.provider.getBalance(alice.address));
  console.log("披露 beneficiaryAddress受益人余额：", ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress)).toString());
  console.log("披露前后alice余额：", balanceBeforeReveal.toString(), balanceAfterReveal.toString());

  // 断言结束时收益人余额增加 2 ETH
  const balanceBeforeEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
  await blindAuction.auctionEnd();
  const balanceAfterEndAuction = ethers.BigNumber.from(await ethers.provider.getBalance(beneficiaryAddress));
  console.log("结束bid前后受益人余额：", balanceBeforeEndAuction.toString(), balanceAfterEndAuction.toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
