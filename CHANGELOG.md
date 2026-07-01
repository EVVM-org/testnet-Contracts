# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - Unreleased

### Codename: "Wraith"

Named after [Wraith](https://www.playdeadlock.com/) from [Deadlock](https://store.steampowered.com/app/1422450/Deadlock/), this release embodies the spirit of precise deal-making and market mastery. Just as Wraith operates the underworld's exchanges with calculated efficiency—setting prices, managing orders, and executing deals with supernatural precision—this release rewrites the P2PSwap contract from the ground up into a clean order book system. The name reflects her identity as the architect of fair exchanges, mirroring how this version introduces VWAP-based price transparency, proportional fee calculation, and a governed proposal system that ensures every market parameter change is deliberate and time-locked.

### Added

- **P2PSwap.sol**: Complete architectural rewrite of the P2P swap contract, replacing the previous implementation with a streamlined order book system:
  - Implemented core order operations (`makeOrder`, `cancelOrder`, `dispatchOrder`) with proportional fee calculation based on order price ratios and VWAP (Volume Weighted Average Price) tracking for market transparency
  - Added administrative proposal system with 1-day timelock for critical parameter changes: admin transitions (`proposeAdmin`), fee rate adjustments (`proposeBasisPercentageFee`), fee distribution splits (`proposeBasisPointsForReward`), and service fee withdrawals (`proposeWithdrawal`)
  - Added helper functions for price calculations and fee management: `getMarketId` (deterministic market ID generation), `applyBasisPoints` (basis point calculations), `getNetPaymentAmount` (proportional payment calculation), `getFeePaymentAmount` (protocol fee calculation), `getVWAP` (market price aggregation), and `collectFees` (service fee accumulation)
  - Added 13 new getter functions to expose all state variables for frontend integration and transparency: `getAdmin`, `getAdminProposal`, `getAdminTimeToAccept`, `getPercentageFee`, `getPercentageFeeProposal`, `getPercentageFeeTimeToAccept`, `getBasisPointsForReward`, `getBasisPointsForRewardProposal`, `getBasisPointsForRewardProposalTime`, `getWithdrawalProposal`, `getTotalFeesCollected`, `getMarketInformation`, `getOrder`
- **Core.sol**: Added 6 new getter functions to expose previously inaccessible state variables and constants: `getETHAddress` (returns `ETH_ADDRESS` constant), `getTreasuryAddress` (returns `treasuryAddress`), `getWindowTimeToChangeEvvmID` (returns `windowTimeToChangeEvvmID`), `getFlagIsStaker` (returns `FLAG_IS_STAKER` constant), `getTimeToAcceptProposal` (returns `TIME_TO_ACCEPT_PROPOSAL` constant), `getTimeToAcceptImplementation` (returns `TIME_TO_ACCEPT_IMPLEMENTATION` constant)
- **P2PSwapError.sol**: Added new custom error library with gas-efficient error definitions for all P2PSwap failure conditions: `NotTheSeller`, `OrderIsUnavailable`, `InsufficientPayment`, `InsufficientAmountToFill`, `SenderIsNotAdmin`, `IncorrectAddressInput`, `ProposalNotReadyToAccept`, `SenderIsNotTheProposedAdmin`, `InvalidBasisPoints`, `ZeroAmount`, `SameTokenPair`, `UnexpectedBehavior`, `IncorrectInput`, `InsufficientAmount`

### Changed

- **P2PSwap.sol**: Refactored admin functions to use proposal pattern with 1-day timelock:
  - Renamed `proposeOwner`/`rejectProposeOwner`/`acceptOwner` to `proposeAdmin`/`rejectProposalAdmin`/`acceptAdmin`
  - Renamed `proposePercentageFee`/`rejectProposePercentageFee`/`acceptPercentageFee` to `proposeBasisPercentageFee`/`rejectProposalBasisPercentageFee`/`acceptBasisPercentageFee`
  - Renamed `proposeFillFixedPercentage`/`rejectProposeFillFixedPercentage`/`acceptFillFixedPercentage` to `proposeBasisPointsForReward`/`rejectProposalBasisPointsForReward`/`acceptBasisPointsForReward`
  - Consolidated `dispatchOrder_fillFixedFee` and `dispatchOrder_fillPropotionalFee` into single `dispatchOrder` function with proportional fee calculation
  - Replaced `balancesOfContract` with `totalFeesCollected` mapping for fee tracking
  - Removed `stake`, `unstake`, `addBalance` functions and `getAllMarketOrders`, `getMyOrdersInSpecificMarket`, `findMarket`, `getMarketMetadata`, `getAllMarketsMetadata`, `getBalanceOfContract`, `getOwner`, `getOwnerProposal`, `getOwnerTimeToAccept`, `getRewardPercentage`, `getRewardPercentageProposal`, `getProposalPercentageFee`, `getMaxLimitFillFixedFee`, `getMaxLimitFillFixedFeeProposal`, `getProposedWithdrawal` getter functions
- **P2PSwapStructs.sol**:
  - Fixed typo in struct name: `WidrawalProposal` → `WithdrawalProposal` (updated all references in `P2PSwap.sol`)
  - Added complete NatSpec documentation for all structs including `@notice`, `@dev`, and `@param` tags
  - Reordered `pragma solidity` statement before `import` statements to comply with Solidity compiler requirements
  - Updated `MarketInformation` struct: removed `tokenA`/`tokenB` fields, added `medianPrice` field for VWAP tracking
  - Updated `Order` struct: renamed `amountA`/`amountB` to `offeredAmount`/`requestedAmount`, added `amountAvailable` for partial fill tracking
  - Added `PercentageProposal` struct for time-delayed fee distribution updates
  - Added `WithdrawalProposal` struct for time-delayed fee withdrawal proposals
- **P2PSwapError.sol**: Corrected error descriptions to accurately reflect their usage context. `UnexpectedBehavior` now describes internal state inconsistencies (e.g., order slot search failures) rather than invalid order IDs. `IncorrectInput` and `InsufficientAmount` descriptions clarified for their specific use cases in withdrawal proposals
- **IP2PSwap.sol**: Updated interface to match new P2PSwap contract functions and removed deprecated function signatures
- **ICore.sol**: Added new getter function signatures: `getETHAddress`, `getFlagIsStaker`, `getTimeToAcceptImplementation`, `getTimeToAcceptProposal`, `getTreasuryAddress`, `getWindowTimeToChangeEvvmID`

### Fixed

- **P2PSwap.sol**: Fixed critical bug in `makeOrder` where `ordersAvailable` counter was not incremented when reusing free order slots, causing permanent desynchronization between the counter and actual active orders. This led to potential underflow in `cancelOrder` and `dispatchOrder` when decrementing the counter, which would revert transactions and block order management for affected markets
- **P2PSwap.sol**: Fixed compilation error in `cancelOrder` where the `order` variable was used in validation checks (`order.seller == address(0)`) before being declared, causing the contract to fail compilation
- **P2PSwap.sol**: Added missing `collectFees` internal function that was being called in `dispatchOrder` to accumulate service fees but was never defined, causing compilation failure

### Removed

- **CLI**: Moved CLI deployment from this repo to https://github.com/EVVM-org/evvm-cli

## [3.1.2] - 2026-04-01

### Changed

- **AdvancedStrings.sol**: Replaced deprecated `/// @solidity memory-safe-assembly` NatSpec comments with the `assembly ("memory-safe") { ... }` block annotation syntax.
- **Treasury.sol** and **NameService.sol**: Replaced direct usage of the `Core` contract with the `ICore` interface, decoupling these contracts from the concrete implementation.

### Fixed

- **Core.sol**: Fixed a re-initialization vulnerability in `initializeSystemContracts` where the `breakerSetupNameServiceAddress` flag was never reset after the initial call, allowing any caller to overwrite `nameServiceAddress` and `treasuryAddress` an unlimited number of times. The flag is now set to `false` at the end of the function, ensuring it can only be executed once.

## [3.1.1] - 2026-03-31

### Changed

- **Treasury.sol**: Refactored `deposit` and `withdraw` functions for improved code clarity. The `withdraw` function now explicitly updates state (`removeAmountFromUser`) before any external calls (ETH/ERC20 transfers), making the Checks-Effects-Interactions pattern more visible. The `deposit` function consolidates the `addAmountToUser` call outside the conditional branches. No security impact—both functions already followed safe patterns.
- **Dependencies**: Updated dependencies to latest versions.

## [3.1.0] - 2026-03-22

### Codename: "Kitsuragi"

Named after [Kim Kitsuragi](https://en.wikipedia.org/wiki/Kim_Kitsuragi) from [Disco Elysium](https://en.wikipedia.org/wiki/Disco_Elysium). Just as Kim methodically verifies every action before it proceeds, this release makes `canExecuteUserTransaction` public and introduces `senderExecutor`/`originExecutor` every transaction must pass through a transparent checkpoint that enforces strict rules while remaining accessible to any external service.

### Changed

- **Use of executors**:
  - All services must now specify `senderExecutor` and `originExecutor` as inputs for transactions. The signature verification in `Core.sol` validates that `senderExecutor` matches the actual caller (`msg.sender`) and `originExecutor` matches the transaction origin (`tx.origin`) when set. This enables flexible multi-service transaction flows while ensuring only authorized executors can process transactions on behalf of users.
  - When a service dispatches payments (e.g., `pay` in `Core.sol`), both `originExecutor` and `senderExecutor` must be set to the service address. This provides clear tracking of payment origins across the EVVM ecosystem and enables complex multi-service transaction flows with full accountability for payment execution.

- **Signature standardization**: To reflect the executor-based transaction flow, the standardized signature payload has been updated:

```
"<evvmID>,<senderExecutor>,<hashPayload>,<originExecutor>,<nonce>,<isAsyncExec>"
```

- **Core.sol**:
  - Refactored `_canExecuteUserTransaction` function to `canExecuteUserTransaction` and made it `public` to allow external services to check if a user transaction can be executed based on the current state of the system, including nonce validation and user validation logic.
  - Change signature and nonce consumption logic in `canExecuteUserTransaction` to be flexible on what service wnat to call, if you put on `senderExecutor` `address(0)` any service with the same signature structure can call it and consume but if you want to restrict it to a specific service you can put the service address and only that service will be able to call it and consume the nonce, this allows for more flexible multi-service transaction flows while maintaining security against attacks.

- **Gas Optimization**:
  - Refactored input handling modifiers across all services to use `calldata` instead of `memory` for external function parameters, reducing gas costs for transactions that involve large data inputs by avoiding unnecessary copying of data into memory.
  - Updated algorithms accross services whose use `for` loops to use `unchecked` blocks where safe to do so, eliminating redundant overflow checks and further reducing gas costs in scenarios with multiple iterations.

- **Core.sol**: Refactored `breakerSetupNameServiceAddress` variable from `bytes1` to `bool` for better gas efficiency.

- **Documentation**: Updated NatSpec documentation across all contracts to reflect changes in transaction execution flow, signature structure, and input handling for improved clarity and maintainability.

- **Testing**: Refactored and added tests to cover new executor-based transaction flow, signature structure, and input handling changes, including scenarios for authorized and unauthorized executors, multi-service transaction flows, and gas optimization effects.

## [3.0.3] - 2026-03-05

### Changed

- **Dependencies**: Updated bun and forge dependencies to latest versions for improved performance and security.

### Fixed

- **EvvmService.sol**: Fixed visibility of `getPrincipalTokenAddress` and `getEvvmID` functions to `public`.

## [3.0.2] - 2026-02-28

### Added

- **Core.sol**:
  - Added `verifyTokenInteractionAllowance` function to check if a token is allowed for interaction (deposit, payment) based on the `allowList` and `denyList` status, improving security and control over token usage in the EVVM ecosystem.
  - Added `proposeListStatus`, `rejectListStatusProposal` and `acceptListStatusProposal` functions to manage proposals for changing the active token list (none, allowList or denyList), enabling a flexible governance mechanism for token permissions in the system.
  - Added `setTokenStatusOnAllowList` and `setTokenStatusOnDenyList` functions to allow the admin to update the status of specific tokens on the allowList and denyList, providing granular control over which tokens are permitted or denied for use in the EVVM.
  - Added `rewardFlowDistribution` flag struct and logic to ensure that if the 99.99% of total supply is distributed the reward flow distribution can be stooped to prevent further rewards from being distributed, which can be used as a safety mechanism to preserve remaining supply in extreme scenarios or be re enabled if needed in the future.
  - Added admin functions to "delete" the maximum supply by setting it to the maximum uint256 value, with a timelock mechanism to prevent immediate deletion and allow for community oversight before such a critical change is made.
  - Added admin functions to change the base reward amount if the total supply is not fixed, with a timelock mechanism to prevent immediate changes and allow for community oversight before such a critical change is made.
- **CoreStorage.sol**: Added `allowList` and `denyList` mappings to track token addresses that are allowed or denied for use in the EVVM, along with `listStatus` to indicate which list is active, providing a flexible mechanism for managing token permissions in the system.
- **ProposalStructs.sol**: Added `Bytes1TypeProposal` struct to represent proposals for bytes1 type parameters.
- **Tests**:
  - Added comprehensive tests for the new token list management functionality in `Core.sol`, including tests for proposing, accepting, and rejecting list status changes, as well as verifying token interaction allowances based on the active list.
  - Added tests for the `rewardFlowDistribution` flag to ensure it correctly stops reward distribution when 99.99% of total supply is distributed and allows re-enabling if needed.
  - Added tests for the new admin functions to delete total supply and change base reward amount, including checks for proper timelock enforcement and access control.

### Changed

- **Core.sol**: Refactor TypeProposal getter functions to return
  - The current status of the proposal
  - The full proposal struct with all details for better transparency and usability in the frontend and other services.
  - Improved `getRandom` with additional entropy sources (blockhash, tx.origin, gasleft).
  - Revert mesages for accepting proposals before timelock have been standardized to `ProposalNotReadyToAccept` for better clarity and consistency across different proposal types in the system.
  - Refactored `getTimeToAcceptImplementation`, `getProposalImplementation` into a single `getFullDetailImplementation` function that returns all variables into a struct for better efficiency and usability in the frontend and other services.
  - Rename `getUserValidatorAddressDetails` to `getFullDetailUserValidator` for better clarity and consistency in naming conventions.
  - Rename `canExecuteUserTransaction` to `_canExecuteUserTransaction` to indicate its internal use and prevent confusion with potential external functions.
- **P2PSwap.sol**: Refactor to remove Metadata struct and replace with direct parameters.

### Fixed

- **CLI:** Fixed bug where all `.executables/*` files were the Linux ELF build; running `./evvm`/`evvm.bat` on macOS or Windows produced “cannot execute binary file”. Wrapper scripts now detect exit‑126 failures, fall back to `bun run cli/index.ts` if Bun is installed, and emit a clear error otherwise. (Proper platform binaries are now produced by CI.)

## [3.0.1] - 2026-02-19

### Fixed

- **Core.sol**: Improved logic in `revokeAsyncNonce` for better handling of nonce revocation scenarios.

## [3.0.0] - 2026-02-17

### Codename: "Ichiban"

Named after [Ichiban Kasuga](https://en.wikipedia.org/wiki/Ichiban_Kasuga) from [Yakuza: Like a Dragon](https://en.wikipedia.org/wiki/Yakuza:_Like_a_Dragon), this release embodies the spirit of rebuilding from the ground up. Just as Ichiban rebuilt his life and united scattered allies into a cohesive team, this release fundamentally restructures EVVM by centralizing previously fragmented functionalities into a unified Core. The name reflects both its literal meaning ("number one") and the protagonist's journey of transforming chaos into order, mirroring how this version consolidates from disparate services into a single, robust foundation for the entire EVVM ecosystem.

### Added

- **Changelog**: Added codenames to releases for a more engaging and memorable version history. The codename will change only in major and minor releases; patch releases are reserved for bug fixes and small improvements that do not require a codename change.
- **Signature standardization**: Implemented a standardized signature payload construction method in `AdvancedStrings.sol` to ensure consistent signature generation and verification across all EVVM services, improving security and interoperability:

```
"<evvmID>,<senderExecutor>,<hashPayload>,<originExecutor>,<nonce>,<isAsyncExec>"
```

- **Core.sol**:
  - A new core contract to:
    - Manage treasury deposits and withdrawals
    - Handle payments
    - Handle signature verification for all EVVM transactions
    - A centralized nonce for async and sync nonce validation across EVVM services preventing replay attacks in multi-service transactions
- **ICore**: Interface for cross-contract interaction with Core.sol
- **Core tests**: Added comprehensive tests for Core.sol covering payment handling, signature verification, and nonce management
- **AdvancedStrings.sol**: `buildSignaturePayload` function for standardized signature generation and verification
- **Hashing utilities**: Added service-specific hashing functions in `/library/utils/signature/` for consistent payload construction across services
- **Deployment script**: Updated to deploy Core.sol and set its address in the services during deployment
- **IUserValidator**: Interface for user validation logic in Core.sol, allowing for flexible access control in evvm transactions
- **CA Verification Library**: Added `CAUtils.sol` for verifying if a certain address is a CA, which can be used in user validation logic in Core.sol
- **CoreExecution Library**: Added `CoreExecution.sol` for handling core execution logic on services.
- **Github templates**:
  - Added `CONTRIBUTING.md` with contribution guidelines for the community
  - Added `PULL_REQUEST_TEMPLATE.md` to standardize pull request submissions and ensure necessary information is provided for reviews
  - Added `SECURITY.md` with security best practices and reporting guidelines for responsible disclosure of vulnerabilities

### Changed

- **Payment service handling inputs**: Change `<variableName>Evvm` or `<variableName>_EVVM` naming convention for all payment handling related variables across services to `<variableName>Pay` to clearly indicate their purpose in payment handling logic
- **Cli**:
  - Changed CLI deployment script to deploy `Core.sol`
  - Updated CLI test script to reflect changes in CLI deployment and interaction with `Core.sol`
  - Updated CLI contract interface generation to include `Core.sol` state variables and functions
  - Updated CLI evvm verification to use `Core.sol`
- **Error handling**: Standardized error naming (e.g., `CoreError`, `NameServiceError`) and established a consistent import aliasing pattern across all services for improved maintainability
- **Payment functions**: Renamed `payMultiple` to `batchPay` and `BatchData` (formerly `PayData`) in `Core.sol` (formerly `Evvm.sol`) for clarity
- **Import paths**: Moved all struct libraries from `contracts/<service>/lib/` to `library/structs/` for better organization
- **Parameter naming**:
  - `priorityFlag` to `isAsyncExec` for clearer async execution identification
- **Contract naming**: Renamed `AdminControlled` to `Admin` in `library/utils/governance/Admin.sol`
- **Core (before called Evvm.sol)**
  - Changed `_setupNameServiceAndTreasuryAddress` to `initializeSystemContracts` to generalize the function for setting up system contracts (NameService, Treasury) in one call during deployment
  - Updated `CoreStructs` (formerly `EvvmStructs`) to interact as a library instead of an abstract contract for better modularity and reuse across services
  - Implemented centralized nonce management and signature verification, replacing Evvm's previous nonce management and signature utilities
- **NameService**:
  - Updated variable name `clowNumber` to `lockNumber` and `expireDate` to `expirationDate` for better clarity
  - Updated `NameServiceStructs` to be a library instead of an abstract contract for better modularity and reuse across services
  - Implemented `Core.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Now both `nonce` and `noncePay` are async nonces managed by `Core.sol` to prevent replay attacks in multi-service transactions, replacing the previous service-specific nonce management
- **P2PSwap**:
  - Implemented `Core.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Now both `nonce` and `noncePay` are async nonces managed by `Core.sol` to prevent replay attacks in multi-service transactions, replacing the previous service-specific nonce management
- **Staking**:
  - Implemented `Core.sol` for nonce validation and signature verification replacing previous service-specific nonce management
  - Updated `StakingStructs` to be a library instead of an abstract contract for better modularity and reuse across services
  - Changed `_setupEstimatorAndEvvm` to `initializeSystemContracts` to generalize the function for setting up all critical system contracts (Evvm, Estimator, Core) in one call during deployment
  - Implemented `nonce` and `noncePay` as async nonces for public and presale staking via `Core.sol` to prevent multi-service replay attacks
- **Cross Chain Treasury**:
  - Implemented `Core.sol` for nonce validation and signature verification replacing previous service-specific nonce management and signature utilities
  - Updated `ExternalChainStationStructs` and `HostChainStationStructs` to be a library instead of an abstract contract for better modularity and reuse across services
- **NatSpec documentation**: Updated and added NatSpec documentation across all contracts for improved clarity and maintainability
- **Testing**: Refactored and added tests to cover new `Core.sol` functionality and its integration with services, including payment handling, signature verification, and nonce management scenarios
- **Github templates**: Updated `bug_report.md` and `feature_request.md` templates to include `Core.sol` as an option

### Removed

- **Evvm.sol**: Renamed to `Core.sol` and refactored to centralize core EVVM functionalities such as payment handling, signature verification, and nonce management
- **Service-specific nonce management**: All nonce management is now centralized in `Core.sol` for improved security and consistency across services
- **Service SignatureUtils**: Removed service-specific signature utilities because signature generation and verification is now centralized in `Core.sol` using `AdvancedStrings.sol` for payload construction
- **Redundant Structs**: Removed all governance-related structs from individual service struct libraries, as they are now centralized in `ProposalStructs.sol` for better organization and reuse
- **Service nonce libraries**: Removed all service-specific nonce libraries, as nonce management is now handled by `Core.sol`
- **Github templates**: Removed references to `Evvm.sol` in `bug_report.md` and `feature_request.md` templates

### Fixed

- **CLI**:
  - Default values for Hyperlane, LayerZero, and Axelar data when user opts not to add on cli deployment script are now properly set to empty values instead of undefined
  - Updated CLI prompts to support async input handling and cursor navigation

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
