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
