const fs = require("fs");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      url: "http://localhost:8545",
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/<INFURA_PROJECT_ID>",
      accounts: [
        {
          privateKey: fs.readFileSync(".secret").toString().trim(),
          balance: "10000000000000000000000",
        },
      ],
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/<INFURA_PROJECT_ID>",
      accounts: [
        {
          privateKey: fs.readFileSync(".secret").toString().trim(),
          balance: "10000000000000000000000",
        },
      ],
    },
  },
  solc: {
    version: "0.8.0",
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
