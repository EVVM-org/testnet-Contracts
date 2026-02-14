# Contributing to EVVM

Thank you for your interest in contributing to EVVM! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [AI Assistance Policy](#ai-assistance-policy)

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) to maintain a welcoming and inclusive community.

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) - Smart contract development framework
- [Bun](https://bun.sh/) - JavaScript runtime for CLI tools
- Git

### Development Setup

1. **Fork the repository**
   ```bash
   # Clone your fork
   git clone https://github.com/YOUR_USERNAME/testnet-contracts.git
   cd testnet-contracts
   ```

2. **Install dependencies**
   ```bash
   # Install Foundry dependencies
   forge install

   # Install CLI dependencies
   bun install
   ```

3. **Build the project**
   ```bash
   forge build
   ```

4. **Run tests**
   ```bash
   forge test
   ```

## How to Contribute

### Reporting Bugs

- Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Search existing issues before creating a new one
- Provide detailed reproduction steps

### Suggesting Features

- Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Explain the problem your feature solves
- Consider the impact on existing functionality

### Contributing Code

1. **Find an issue to work on**
   - Look for issues labeled `good first issue` or `help wanted`
   - Comment on the issue to let others know you're working on it

2. **Create a branch**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make your changes**
   - Follow the [coding standards](#coding-standards)
   - Write tests for new functionality
   - Update documentation as needed

4. **Submit a Pull Request**
   - Use the [Pull Request template](.github/PULL_REQUEST_TEMPLATE.md)
   - Link related issues
   - Request review from maintainers

## Coding Standards

### Solidity

- **Version**: Use Solidity ^0.8.20 or as specified in `foundry.toml`
- **Formatting**: Follow the project's existing style
- **Naming Conventions**:
  - Contracts: `PascalCase`
  - Functions: `camelCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Private/internal variables: `_prefixedCamelCase`
  - Events: `PascalCase`
  - Errors: Use `ErrorsLib` for centralized error management

### Documentation

- Add NatSpec comments to all public/external functions
- Include `@notice`, `@dev`, `@param`, and `@return` tags
- Update README if adding new features

### Example

```solidity
/// @notice Transfers tokens from one address to another
/// @dev Requires prior approval from the sender
/// @param from The address to transfer from
/// @param to The address to transfer to
/// @param amount The amount to transfer
/// @return success Whether the transfer was successful
function transferFrom(
    address from,
    address to,
    uint256 amount
) external returns (bool success) {
    // Implementation
}
```

### TypeScript (CLI)

- Use TypeScript for all CLI code
- Follow existing patterns in `cli/` directory
- Add types for all function parameters and return values

## Testing Guidelines

### Writing Tests

- Place unit tests in `test/unit/`
- Place fuzz tests in `test/fuzz/`
- Name test files matching the contract: `ContractName.t.sol`
- Use descriptive test names: `test_testType_functionName_specificScenario`

### Running Tests

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/unit/YourTest.t.sol

# Run specific test
forge test --match-test test_yourTestName

# Run with verbosity
forge test -vvv

# Run with gas report
forge test --gas-report
```

### Test Coverage

- Aim for high coverage on critical functions
- Cover edge cases and error conditions
- Test access control restrictions

## Pull Request Process

1. **Before submitting**
   - [ ] All tests pass (`forge test`)
   - [ ] Code compiles without warnings (`forge build`)
   - [ ] Documentation is updated
   - [ ] Commit messages are clear and descriptive

2. **PR Requirements**
   - Fill out the PR template completely
   - Link related issues
   - Provide clear description of changes
   - Include gas impact for optimization PRs

3. **Review Process**
   - At least one maintainer approval required
   - All CI checks must pass
   - Address reviewer feedback promptly

4. **After Merge**
   - Delete your branch
   - Update related issues

## AI Assistance Policy

We welcome contributions that use AI tools, but transparency is required.

### Disclosure Requirements

When submitting issues or pull requests:
- Indicate if AI tools were used (GitHub Copilot, ChatGPT, Claude, etc.)
- Specify which parts were AI-generated or AI-assisted
- Ensure you understand and can explain all submitted code

### Guidelines for AI-Assisted Contributions

- **Review AI output**: Don't blindly accept AI-generated code
- **Test thoroughly**: AI-generated code may contain subtle bugs
- **Understand the code**: Be prepared to explain and defend your changes
- **Security review**: Pay extra attention to security in AI-generated code
- **Attribution**: Be honest about what was AI-assisted

### Why We Require Disclosure

- Helps reviewers focus attention appropriately
- Maintains code quality and security standards
- Builds trust within the community
- Improves our understanding of AI tool effectiveness

## Project Structure

```
├── src/
│   ├── contracts/          # Main contracts
│   │   ├── core/           # EVVM core
│   │   ├── nameService/    # Name service
│   │   ├── staking/        # Staking contracts
│   │   └── treasury*/      # Treasury contracts
│   ├── interfaces/         # Contract interfaces
│   └── library/            # Shared libraries
├── test/
│   ├── unit/               # Unit tests
│   └── fuzz/               # Fuzz tests
├── script/                 # Deployment scripts
├── cli/                    # CLI tools
└── lib/                    # External dependencies
```

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create an issue using the bug template
- **Security**: See [SECURITY.md](SECURITY.md)

## Recognition

Contributors will be recognized in:
- Release notes for significant contributions

---

Thank you for contributing to EVVM!
