# Diamond Proxy Contract for PetroCoin

## Description

This upgradeable contract is developed by Yan Digilov and is used to create a proxy contract for the PetroCoin project. The contract is based on the Diamond Standard and is used to upgrade the PetroCoin contract without losing the state of the contract.

## Key Components

## Dependencies

- Install [foundry](https://book.getfoundry.sh)
- Install [string-utils](https://github.com/Arachnid/solidity-stringutils)

## Testing

To run all of the tests use the command

```bash
   $ forge test --ffi --match-path test/DiamondTests.t.sol
```

To run only diamond deployment tests use the command

```bash
   $ forge test --ffi --match-contract TestDeployDiamond
```

To deploy on Sepolia run:

```bash
   $ forge script --chain sepolia script/SepoliaDeploy.sol:DeployDiamondSepolia --rpc-url $SEPOLIA_RPC_URL --private-key <PRIVATE KEY> --broadcast --verify -vvvv --ffi
```

[{"inputs":[{"internalType":"address","name":"_user","type":"address"},{"internalType":"address","name":"_contractOwner","type":"address"}],"name":"NotContractOwner","type":"error"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"}],"name":"Unpaused","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getOwnerHoldPeriod","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getProducerHoldPeriod","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getTreasureryBalance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"},{"internalType":"uint256","name":"_totalSupply","type":"uint256"},{"internalType":"uint8","name":"_decimals","type":"uint8"},{"internalType":"uint256","name":"_ownerHoldPeriod","type":"uint256"},{"internalType":"uint256","name":"_producerHoldPeriod","type":"uint256"}],"name":"initErc20PetroCoin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"isPaused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintProducerTokens","outputs":[{"internalType":"contract TokenTimelock","name":"timelock","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_ownerHoldPeriod","type":"uint256"}],"name":"setOwnerHoldPeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_producerHoldPeriod","type":"uint256"}],"name":"setProducerHoldPeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferTreasuryTokens","outputs":[{"internalType":"contract TokenTimelock","name":"timelock","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"}]
