# 🔋 Solidity语法基础与进阶项目

## ☎️ basic 基础语法

使用REMIX的单元测试编写了基础的盲拍系统，使用时将 test/remix文件夹中的文件复制到remix中执行测试，需要注意

- 使用 #value 和 #sender 这两个NatSpec前提是testSuit继承目标合约
- 方法需要传递ETH原生币需要加 payable 关键字
- 可以通过 import "forge-std/console2.sol" 在合约中打印
- remix提供的单元测试功能存在诸多缺陷：
  - 必须继承才可以使用#value 和 #sender
  - 无法看到详细的报错信息
  - 因为要使用到继承，许多初始化和调用会收到影响
  - 在remix IDE中测试速度慢，存在崩溃的情况，服务不稳定

## 🖥 pro 进阶语法
foundry分支
hardhat分支
测试脚本使用Foundry编写

```shell
$ forge build
$ forge test --match-contract OpenAuctionTest -vv
$ forge test --match-contract BlindAuctionTest -vv
```
