# Diamond Proxy Contract for PetroCoin

## Description

This upgradeable contract is developed by Yan Digilov and is used to create a proxy contract for the PetroCoin project. The contract is based on the Diamond Standard and is used to upgrade the PetroCoin contract without losing the state of the contract.

> New to PetroCoin, or not a developer? See the [User Guide](USER_GUIDE.md) for a plain-English explanation of how PTCN, vaults, and receipt tokens work, and how to add them to your wallet.

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

To run full vault audit run:

```bash
$forge script --chain mainnet script/FullVaultAudit.sol:FullVaultAudit --rpc-url https://eth-mainnet.g.alchemy.com/v2/API*HERE --private-key **PRIVATE_KEY -vvvv --ffi --broadcast
```

To check coverage in an html report run:

```bash
forge coverage --ffi --report lcov && genhtml lcov.info -o coverage && open coverage/index.html
```
