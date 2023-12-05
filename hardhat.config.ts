import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv"
dotenv.configDotenv()


const config: HardhatUserConfig = {
  solidity: "0.8.20",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        enabled: true, 
        url: "https://eth-mainnet.g.alchemy.com/v2/Em-KZ_xfF6hx2jtKFo3l3YKDGhghwBgC",
      }
    },
    sepolia: {
      chainId: 11155111,
      url: process.env.ETH_SEPOLIA,
      accounts: [`0x${process.env.WALLET_PK}`]
    },
    eth: {
      chainId: 1, 
      url: process.env.ETH_MAINNET, 
      accounts: [`0x${process.env.WALLET_PK}`]
    }
  }
};

export default config;
