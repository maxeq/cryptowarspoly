import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";
dotenv.config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY!;
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY!;
const POLYGON_SCAN_KEY = process.env.POLYGON_SCAN_KEY!;

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [MUMBAI_PRIVATE_KEY]
    }
  },
etherscan: {
  apiKey: {
    mumbai: POLYGON_SCAN_KEY
  },
  customChains: [
    {
      network: "mumbai",
      chainId: 80001,
      urls: {
        apiURL: "https://api-testnet.polygonscan.com/api",
        browserURL: "https://mumbai.polygonscan.com/"
      }
    }
  ]
}
};

export default config;
