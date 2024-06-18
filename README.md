# FID20 Token Contract

This repo contains an example FID20 contract. FID20 tokens are ERC20 tokens that can only be owned and traded by wallets with Farcaster accounts. This is possible on Ham chain where Farcaster ID (FID) to wallet mappings exist natively onchain.

[Learn more](https://docs.ham.fun/docs/farcaster-data) about Ham chain and onchain Farcaster data by reading the docs.

![Ham Logo](https://ham.fun/ham-icon.svg)

## Running tests

You can run fork tests that interact with a forked version of Ham chain. This ensures that the tests will be able to access onchain FID to wallet mappings.

```
forge test --fork-url https://rpc.ham.fun --match-path ./test/FID20.t.sol  -vvv
```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
