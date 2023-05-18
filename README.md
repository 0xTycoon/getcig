# Oracles for CigToken & getcig.eth app

This project implements has a basic Uniswap V2 oracle for the Cigarette Token.

The oracle os used by the `getcig.sol` contract to ensure that the user is getting a fair price for their ETH, and the transaction is more difficult to tamper with.

`oracle.sol` is the original example from Uniswap

`cigoracle.sol` is an oracle that only measures the ETH price in cig. Used by `getcig.eth` for buying cig with ETH.

rename `hardhat.config.example.js` to `hardhat.config.js` and configure to your needs.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test

```
