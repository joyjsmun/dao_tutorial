require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({path:".env"});

const QUICKNODE_HTTP_URL = process.env.QUICKNODE_HTTP_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks:{
    hardhat: {
      allowUnlimitedContractSize: true
    },
    goerli:{
      url: QUICKNODE_HTTP_URL,
      accounts:[PRIVATE_KEY],

    }
  }
};
