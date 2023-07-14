import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
import * as tdly from "@tenderly/hardhat-tenderly";
import * as dotenv from "dotenv";
dotenv.config();
const {
  TENDERLY_PROJECT_SLUG,
  TENDERLY_USER_NAME,
  TENDERLY_ACCESS_KEY,
  DEVNET_RPC_URL,
  TENDERLY_PRIVATE_VERIFICATION,
  TENDERLY_AUTOMATIC_VERIFICATIONS
}= process.env;
//是否发布时自动Verify
tdly.setup({automaticVerifications: TENDERLY_AUTOMATIC_VERIFICATIONS == 'true'})

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

module.exports = {
  solidity: {
    compilers: [
      {
          version: '0.8.17',
          settings: {
              optimizer: {
                  details: {
                      yul: true,
                  },
                  enabled: true,
                  runs: 200
              },
          },
      },
      ],
  },
  networks: {
    localhost: {
      url: DEVNET_RPC_URL,
      chainId: 1,
    },
    PolygonMumbai: {
      url: `https://rpc-mumbai.maticvigil.com`,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    apiKey: {
      polygonMumbai: process.env.POLYGONMUMBAI_SCAN_API_KEY,
    },
  },
  tenderLy: {
    project: TENDERLY_PROJECT_SLUG,
    username: TENDERLY_USER_NAME,
    accessKey: TENDERLY_ACCESS_KEY,
    privataVerificat1on: TENDERLY_PRIVATE_VERIFICATION !='false'
  },
  namedAccounts: {
    deployer:{
      default:0
    },
    governanon: {
      default: 0
    },
    delegator: {
      default: 1
    },
    vaultManager:{
      default: 2
    },
    keeper: {
      default: 3
    },
    usenr: {
      default: 4
    },
    friend: {
      default:5
    }
  }
}
