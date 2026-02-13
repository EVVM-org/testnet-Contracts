# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - [Unreleased]

### Codename: "Ichiban"

### Added

- **Changelog**: Added codenames to releases for a more engaging and memorable version history
- **State.sol**: Centralized nonce coordinator for async and sync nonce validation across EVVM services, preventing replay attacks in multi-service transactions
- **AdvancedStrings.sol**: `buildSignaturePayload` function for standardized signature generation and verification
- **CLI**: State interface generator
- **IState**: Interface for cross-contract interaction with State.sol
- **Hashing utilities**: Added service-specific hashing functions in `/library/utils/signature/` for consistent payload construction across services
- **Deployment script**: Updated to deploy State.sol and set its address in the services during deployment
- **StateManagment**: Added `StateManagment.sol` library for services to interact with State.sol for nonce management and signature verification
- **IUserValidator**: Interface for user validation logic in State.sol, allowing for flexible access control in evvm transactions
- **CA Verification Library**: Added `CAUtils.sol` for verifying if a certain address is a CA, which can be used in `State.sol` for access control in async transactions and `Evvm.sol` for validating CaPay transactions

### Changed

- **Error handling**: Updated error imports for all services (including the EVVM core contract) to `ErrorsLib` from `<service>Error` for improved readability and maintainability
- **Payment functions**: Renamed `payMultiple` to `batchPay` and `PayData` to `BatchData` in Evvm.sol for clarity
- **Import paths**: Moved all struct libraries from `contracts/<service>/lib/` to `library/structs/` for better organization
- **Parameter naming**:
  - `priorityFlag` to `isAsyncExec` for clearer async execution identification
- **Contract naming**: Renamed `AdminControlled` to `Admin` in `library/utils/governanceUtils.sol`
- **EVVM core service**
  - Changed `_setupNameServiceAndTreasuryAddress` to `initializeSystemContracts` to generalize the function for setting up all critical system contracts (NameService, Treasury, State) in one call during deployment
  - Updated `EvvmStructs` to interact as a library instead of an abstract contract for better modularity and reuse across services
  - Implemented `State.sol` for centralized nonce management and signature verification, replacing Evvm's previous nonce management and signature utilities
- **NameService**:
  - Updated variable name `clowNumber` to `lockNumber` and `expireDate` to `expirationDate` for better clarity
  - Updated `NameServiceStructs` to be a library instead of an abstract contract for better modularity and reuse across services
  - Implemented `State.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Now both `nonce` and `nonceEvvm` are async nonces managed by `State.sol` to prevent replay attacks in multi-service transactions, replacing the previous service-specific nonce management
- **P2PSwap**:
  - Implemented `State.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Now both `nonce` and `nonceEvvm` are async nonces managed by `State.sol` to prevent replay attacks in multi-service transactions, replacing the previous service-specific nonce management
- **Staking**:
  - Implemented `State.sol` for nonce validation and signature verification replacing previous service-specific nonce management
  - Updated `StakingStructs` to be a library instead of an abstract contract for better modularity and reuse across services
  - Changed `_setupEstimatorAndEvvm` to `initializeSystemContracts` to generalize the function for setting up all critical system contracts (Evvm, Estimator, State) in one call during deployment
  - Implemented `nonce` and `nonceEvvm` as async nonces for public and presale staking via `State.sol` to prevent multi-service replay attacks
- **Cross Chain Treasury**:
  - Implemented `State.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Updated `ExternalChainStationStructs` and `HostChainStationStructs` to be a library instead of an abstract contract for better modularity and reuse across services
- **NatSpec documentation**: Updated and added NatSpec documentation across all contracts for improved clarity and maintainability

### Removed

- **Service-specific nonce management**: All nonce management is now centralized in `State.sol` for improved security and consistency across services
- **Service SignatureUtils**: Removed service-specific signature utilities because signature generation and verification is now centralized in `State.sol` using `AdvancedStrings.sol` for payload construction
- **Redundant Structs**: Removed all governance-related structs from individual service struct libraries, as they are now centralized in `GovernanceUtils.sol` for better organization and reuse
- **Service nonce libraries**: Removed all service-specific nonce libraries, as nonce management is now handled by `State.sol`

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
