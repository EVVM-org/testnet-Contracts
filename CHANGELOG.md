# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - [Unreleased]

### Added

### Changed
- Updated error imports for all services (including the EVVM core contract) to `ErrorsLib` from `<service>Error` for improved readability and maintainability

### Removed

### Fixed
- Default values for Hyperlane, LayerZero, and Axelar data when user opts not to add on cli deployment script are now properly set to empty values instead of undefined

## [2.3.0] - 2026-01-26

### Added
- Added `CHANGELOG.md` file to document changes in the project
- Complete NatSpec documentation for all contracts
- NatSpec for `evvm/lib/` (ErrorsLib, EvvmStorage, EvvmStructs, SignatureUtils)
- NatSpec for `nameService/lib/` (ErrorsLib, IdentityValidation, NameServiceStructs, SignatureUtils)
- NatSpec for `staking/lib/` (ErrorsLib, SignatureUtils, StakingStructs)
- NatSpec for `treasury/lib/` (ErrorsLib)
- NatSpec for `library/` (EvvmService, SignatureRecover, AdvancedStrings, nonces, service utils)
- NatSpec for `Estimator.sol`
- Updated GitHub Issue Templates (bug_report.md, feature_request.md)
- Added `getEvvmID` function in `EvvmService.sol` for backend imporves 

### Changed
- Improved documentation clarity for community developers
- Improve testing scripts for more clarity during debugging phase
- Improved issue templates for better reporting and disclosure of AI tools used 
- Improved `payMultiple` function on `Evvm.sol` to be more gas efficient and more legible
- Replace all import interfaces on `src/contracts` files for the respective contract

### Fixed
- Missing `@dev` documentation for `evvm` variable in NameService.sol
- Replace hardcoded PRINCIPAL_TOKEN_ADDRESS with evvm.getPrincipalTokenAddress() in `NameService.sol` and `Staking.sol`
