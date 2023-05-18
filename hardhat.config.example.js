require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-chai-matchers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [

            {
                version: "0.6.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    },

                }
            },

        ],
        overrides: {
            "contracts/getcig.sol": {
                version: "0.8.19",
                settings: {}
            }
        }


    },
    mocha: {
        timeout: 90000
    },
    defaultNetwork: "hardhat",
    networks: {

        // when running the migration-test.js or stogie.js
        // uncomment the following and get an API key from https://www.alchemy.com/
        // /*
        hardhat: {
            forking: {
                url: "https://eth-mainnet.alchemyapi.io/v2/PASTE_YOUR_KEY_HERE",
                //blockNumber: 14487179 // if you want to home in on a specific block
                blockNumber: 17282918
            },
            allowUnlimitedContractSize: true
        },


    }

};
