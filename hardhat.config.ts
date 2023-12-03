import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv"
dotenv.configDotenv()


const config: HardhatUserConfig = {
  solidity: "0.8.20",
  defaultNetwork: "sepolia",
  networks: {
    hardhat: {},
    sepolia: {
      chainId: 11155111,
      url: process.env.ETH_SEPOLIA,
      accounts: [`0x${process.env.WALLET_PK}`]
    }
  }
};

export default config;
