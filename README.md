# FID20 Token Contract

**Version 1.0.0**

This repository contains an example FID20 contract. FID20 tokens are ERC20 tokens that can only be owned and traded by wallets with Farcaster accounts. This is possible on the Ham chain where Farcaster ID (FID) to wallet mappings exist natively onchain.

[Learn more](https://docs.ham.fun/docs/farcaster-data) about the Ham chain and onchain Farcaster data by reading the docs.

![Ham Logo](https://ham.fun/ham-icon.svg)

## What is FID20?

The FID20 standard is an extension of the ERC20 token standard. It introduces additional functionality to ensure that tokens can only be transferred to and from wallets associated with Farcaster accounts. This functionality is facilitated by the Ham chain, which provides native onchain mappings between Farcaster IDs and wallet addresses.

### Key Features:
- **Restricted Transfers**: Tokens can only be transferred to addresses that have associated Farcaster accounts.
- **Allowlist**: An allowlist mechanism is provided to permit specific addresses, such as smart contracts, to interact with the tokens even if they don't have a Farcaster account.

### Who Created FID20?

The FID20 standard was developed by apex777.eth. The aim is to provide a more secure and accountable way to manage token transfers, leveraging the Farcaster network.

## Example Token

Included in this repository is an example implementation of the FID20 standard in the form of a "memecoin" style token. This token serves as an educational resource to help developers understand how to implement and use the FID20 standard.

### Token Details:
- **Name**: Example FID20 Token
- **Ticker**: FID20
- **Max Supply**: 100,000,000 tokens

## Running Tests

You can run fork tests that interact with a forked version of the Ham chain. This ensures that the tests will be able to access onchain FID to wallet mappings.

```sh
forge test --fork-url https://rpc.ham.fun --match-path ./test/FID20.t.sol -vvv
