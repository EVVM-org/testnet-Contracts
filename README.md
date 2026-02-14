# EVVM Testnet Contracts

![Version](https://img.shields.io/badge/version-3.0.0%20%22Ichiban%22-red.svg)
![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?logo=foundry)
![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-3178C6?logo=typescript)
![Bun](https://img.shields.io/badge/Runtime-Bun-000000?logo=bun)
[![license](https://img.shields.io/badge/license-EVVM--NONCOMMERCIAL--1.0-blue.svg)](LICENSE)
[![docs](https://img.shields.io/badge/docs-evvm.info-blue.svg)](https://www.evvm.info/)
[![npm downloads](https://img.shields.io/npm/dw/@evvm/testnet-contracts.svg)](https://www.npmjs.com/package/@evvm/testnet-contracts)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A compact toolkit for creating virtual EVM chains on testnets.

Two ways to use EVVM:

1. As a library - Import Solidity contracts in your dApp
2. As a CLI tool - Deploy and manage EVVM instances on testnets

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

## Use as a CLI Tool (for EVVM deployment)

### Requirements

Before deploying with the CLI, ensure you have the following installed:

- **Foundry** - [Install](https://getfoundry.sh/introduction/installation/)
- **Bun** (≥ 1.0) - [Install](https://bun.sh/)
- **Git** - [Install](https://git-scm.com/downloads)

### Quick start (2 min)

1. Clone & install

```bash
git clone --recursive https://github.com/EVVM-org/Testnet-Contracts
cd Testnet-Contracts

# Option 1: Using CLI (recommended)
chmod +x ./evvm
./evvm install

# Option 2: Manual installation
bun install
forge install
```

2. Prepare environment

```bash
cp .env.example .env
# Edit RPC_URL, ETHERSCAN_API, etc.
```

3. Import wallet (secure)

```bash
cast wallet import defaultKey --interactive
```

4. Deploy (interactive)

If you are on Linux or macOS, run:

```bash
./evvm deploy
```

If you are on Windows, run on PowerShell:

```powershell
.\evvm.bat deploy
```

Or use Bun from any directory:

```bash
bun run evvm deploy
```

**Using CLI Scripts (Recommended for local development)**

The repository includes platform-specific wrapper scripts to easily call the CLI:

**Linux/macOS:**

```bash
# Make script executable (first time only)
chmod +x ./evvm

# Run any EVVM CLI command
./evvm deploy
./evvm register --coreAddress 0x...
./evvm developer --makeInterface
./evvm help
```

**Windows (PowerShell):**

```powershell
# Run any EVVM CLI command
.\evvm.bat deploy
.\evvm.bat register --coreAddress 0x...
.\evvm.bat developer --makeInterface
.\evvm.bat help
```

The scripts automatically detect your OS and architecture (x64, ARM64, MUSL) and execute the appropriate compiled binary from `.executables/` folder.

Quick Start (CLI): https://www.evvm.info/docs/QuickStart

## CLI - Available Commands

**Deployment & Registration:**

- `evvm deploy` # Deploy EVVM (single or cross-chain)
- `evvm deploy --skipInputConfig` # Deploy with existing config (no prompts)
- `evvm deploy --crossChain` # Deploy cross-chain EVVM instance
- `evvm register --coreAddress <addr>` # Register EVVM in registry
- `evvm register --crossChain` # Register cross-chain EVVM

**Cross-Chain Management:**

- `evvm setUpCrossChainTreasuries` # Configure treasury station connections

**Developer Utilities:**

- `evvm developer --makeInterface` # Generate Solidity interfaces from contracts
- `evvm developer --runTest` # Run test suites with custom filters
- `evvm install` # Install Bun and Foundry dependencies

**Information:**

- `evvm help` # Show comprehensive CLI help
- `evvm version` # Show CLI version

## Library Usage (Quick Reference)

- **NPM install:** `npm install @evvm/testnet-contracts`
- **Forge install:** `forge install EVVM-org/Testnet-Contracts`
- **Import in Solidity:** `import "@evvm/testnet-contracts/interfaces/ICore.sol";`

## Troubleshooting

- **RPC timeouts**: CLI automatically tries fallback RPCs; set `RPC_URL` in `.env` to a reliable endpoint.
- **Wallet not found**: import with `cast wallet import <name> --interactive`.
- **Bun missing**: install Bun (`curl -fsSL https://bun.sh/install | bash`).
- **Tests**: run `./evvm developer --runTest` (Linux/Mac) or `evvm.bat developer --runTest` (Windows), or `forge test`.
- **Script not executable (Linux/Mac)**: run `chmod +x ./evvm` and ensure `.executables/` binaries have execute permissions.
- **Wrong architecture detected**: The wrapper scripts auto-detect OS/architecture. If issues occur, manually run the correct binary from `.executables/`.

Files & structure (short)

- `src/contracts/` — core contracts (Evvm, NameService, Staking, Treasury, P2PSwap)
- `cli/` — TypeScript CLI source
- `script/` — Foundry deployment scripts
- `input/` — optional JSON/Sol files generated by CLI
- `.executables/` — pre-compiled CLI binaries for multiple platforms
- `evvm` — Linux/macOS CLI wrapper script (auto-detects architecture)
- `evvm.bat` — Windows CLI wrapper script (auto-detects architecture)

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
