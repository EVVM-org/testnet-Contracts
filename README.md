# EVVM Testnet Contracts

![Version](https://img.shields.io/badge/version-3.1.2%20%22Wraith%22-red.svg)
![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?logo=foundry)
![Bun](https://img.shields.io/badge/Runtime-Bun-000000?logo=bun)
[![license](https://img.shields.io/badge/license-EVVM--NONCOMMERCIAL--1.0-blue.svg)](LICENSE)
[![docs](https://img.shields.io/badge/docs-evvm.info-blue.svg)](https://www.evvm.info/)
[![npm downloads](https://img.shields.io/npm/dw/@evvm/testnet-contracts.svg)](https://www.npmjs.com/package/@evvm/testnet-contracts)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A compact toolkit for creating virtual EVM chains on testnets.

Docs & hosted library: https://www.evvm.info/

## Use as a Library (for dApp developers)

### Install the library (1 min)

**NPM (recommended):**

```bash
npm install @evvm/testnet-contracts
```

**Or with Forge:**

```bash
forge install EVVM-org/Testnet-Contracts
```

**Import in your contracts:**

```solidity
import "@evvm/testnet-contracts/interfaces/ICore.sol";
```

Guide: How to build on top of EVVM: https://www.evvm.info/docs/HowToMakeAEVVMService

## Security & Contributing

### How to Contribute

We welcome contributions from the community! Here's how you can help:

1. **Report Issues** - Found a bug or have a suggestion? [Open an issue on GitHub](https://github.com/EVVM-org/Testnet-Contracts/issues)
2. **Suggest Features** - Have an idea for improvement? [Create a feature request issue](https://github.com/EVVM-org/Testnet-Contracts/issues)
3. **Submit Code Changes**:
   - Fork the repository
   - Create a feature branch (`git checkout -b feature/amazing-feature`)
   - Make your changes and add tests
   - Push to your branch (`git push origin feature/amazing-feature`)
   - Submit a Pull Request with a detailed description

### Guidelines

- **Issues**: Use [GitHub Issues](https://github.com/EVVM-org/Testnet-Contracts/issues) for bug reports, feature requests, and discussions
- **Pull Requests**: Each PR should reference a related issue
- **Tests**: All new features must include tests
- **Code Style**: Follow the existing code patterns in the repository
- **Commit Messages**: Write clear, descriptive commit messages

## Security Best Practices

- **Never commit private keys**: Always use `cast wallet import <YOUR_ALIAS> --interactive` to securely store your keys
- **Use test credentials only**: This repository is for testnet deployment only
- **Environment variables**: Store sensitive data like API keys in `.env` files (not committed to git)
- **Verify contracts**: Always verify your deployed contracts on block explorers
