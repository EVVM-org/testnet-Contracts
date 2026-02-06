# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - [Unreleased]

### Added
- **State.sol**: Centralized nonce coordinator for async and sync nonce validation across EVVM services, preventing replay attacks in multi-service transactions
- **AdvancedStrings.sol**: `buildSignaturePayload` function for standardized signature generation and verification
- **CLI**: State interface generator
- **IState**: Interface for cross-contract interaction with State.sol

### Changed
- **Error handling**: Updated error imports for all services (including the EVVM core contract) to `ErrorsLib` from `<service>Error` for improved readability and maintainability
- **Payment functions**: Renamed `payMultiple` to `batchPay` and `PayData` to `BatchData` in Evvm.sol for clarity
- **Import paths**: Moved all struct libraries from `contracts/<service>/lib/` to `library/structs/` for better organization
- **Parameter naming**: 
  - `priorityFlag` to `isAsyncExec` for clearer async execution identification
  - `clowNumber` to `lockNumber` in NameService related functions
- **Contract naming**: Renamed `AdminControlled` to `Admin` in `library/utils/governanceUtils.sol`

### Removed

### Fixed
- **CLI**: Default values for Hyperlane, LayerZero, and Axelar data when user opts not to add on cli deployment script are now properly set to empty values instead of undefined

## [2.3.0] - 2026-01-26

### Added
- `CHANGELOG.md` to track project changes
- `getEvvmID` function in `EvvmService.sol` for backend improvements
- **NatSpec documentation** for all contracts:
  - Core library contracts: ErrorsLib, EvvmStorage, EvvmStructs, SignatureUtils (evvm/lib/)
  - NameService library: ErrorsLib, IdentityValidation, NameServiceStructs, SignatureUtils
  - Staking library: ErrorsLib, SignatureUtils, StakingStructs
  - Treasury library: ErrorsLib
  - Shared libraries: EvvmService, SignatureRecover, AdvancedStrings, nonces, service utils
  - Estimator.sol contract

### Changed
- **Documentation**: Improved clarity for community developers
- **Issue templates**: Enhanced bug_report.md and feature_request.md with AI tools disclosure
- **Testing**: Improved script clarity for debugging phase
- **Gas optimization**: Refactored `payMultiple` function in Evvm.sol for better efficiency and readability
- **Imports**: Replaced interface imports with direct contract imports in `src/contracts` files

### Fixed
- Missing `@dev` documentation for `evvm` variable in NameService.sol
- Hardcoded PRINCIPAL_TOKEN_ADDRESS replaced with `evvm.getPrincipalTokenAddress()` in NameService.sol and Staking.sol
