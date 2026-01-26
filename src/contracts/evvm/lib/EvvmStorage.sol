// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {EvvmStructs} from "./EvvmStructs.sol";

/**
 * @title EvvmStorage
 * @author Mate labs
 * @notice Storage layout contract exclusively for the Evvm.sol core contract
 * @dev This contract inherits all structures from EvvmStructs and defines
 *      the storage layout used by the Evvm.sol proxy pattern implementation.
 *      All state variables declared here are used by Evvm.sol and its upgradeable
 *      implementation contracts.
 *
 * Storage Organization:
 * - Constants: System-wide immutable values
 * - External Addresses: Integration points with other contracts
 * - Governance State: Admin and proposal management
 * - Balance Management: User token balances and nonce tracking
 * - Configuration: System parameters and metadata
 *
 * @custom:inheritance Inherited by Evvm.sol, should not be deployed directly
 * @custom:scope Exclusive to Evvm.sol contract and its implementations
 * @custom:proxy Storage layout must remain consistent across upgrades
 */

abstract contract EvvmStorage is EvvmStructs {
    //░▒▓█ Constants ██████████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Sentinel address representing native ETH in token operations
     * @dev address(0) is used to represent the native blockchain token (ETH, MATIC, etc.)
     */
    address constant ETH_ADDRESS = address(0);

    /**
     * @notice Flag value indicating an address is a registered staker
     * @dev Used in stakerList mapping to mark addresses with staking privileges
     *      Value of 0x01 indicates active staker status
     */
    bytes1 constant FLAG_IS_STAKER = 0x01;

    /**
     * @notice Time delay required before accepting admin change proposals
     * @dev 1 day delay provides time for community review of admin changes
     *      Used in proposeAdmin and acceptAdmin functions
     */
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /**
     * @notice Time delay required before accepting implementation upgrades
     * @dev 30 day delay provides extended review period for critical contract upgrades
     *      Used in proposeImplementation and acceptImplementation functions
     */
    uint256 constant TIME_TO_ACCEPT_IMPLEMENTATION = 30 days;

    //░▒▓█ External Contract Addresses █████████████████████████████████████████████████▓▒░

    /**
     * @notice Address of the NameService contract for identity resolution
     * @dev Used to resolve username identities to wallet addresses in payment functions
     *      Enables payments to usernames like "alice.evvm" instead of raw addresses
     */
    address nameServiceAddress;

    /**
     * @notice Address of the authorized staking contract
     * @dev Controls staker status updates and receives staking-related rewards
     *      Only this address can call pointStaker() to update staker status
     */
    address stakingContractAddress;

    /**
     * @notice Address of the Treasury contract with privileged balance operations
     * @dev Can call addAmountToUser and removeAmountFromUser for token management
     *      Used for cross-chain bridging, reward distributions, and system operations
     */
    address treasuryAddress;

    //░▒▓█ Token Whitelist Proposal State ██████████████████████████████████████████████▓▒░

    /**
     * @notice Address of the token pending whitelist approval
     * @dev Part of time-delayed token whitelisting mechanism
     *      Set during prepareWhitelistToken(), cleared on acceptance
     */
    address whitelistTokenToBeAdded_address;

    /**
     * @notice Liquidity pool address for the token pending whitelist approval
     * @dev Used to validate token has sufficient liquidity before whitelisting
     *      Typically a Uniswap V3 pool address
     */
    address whitelistTokenToBeAdded_pool;

    /**
     * @notice Timestamp when the pending token whitelist can be accepted
     * @dev After this timestamp, the token can be officially whitelisted
     *      Zero value indicates no pending whitelist proposal
     */
    uint256 whitelistTokenToBeAdded_dateToSet;

    //░▒▓█ Proxy Implementation State ██████████████████████████████████████████████████▓▒░

    /**
     * @notice Address of the current active implementation contract
     * @dev All non-matching function calls are delegated to this address
     *      Updated through time-delayed governance process
     * @custom:proxy Slot used by assembly in fallback for delegatecall
     */
    address currentImplementation;

    /**
     * @notice Address of the proposed implementation for upgrade
     * @dev Set by admin, becomes active after time delay via acceptImplementation()
     *      Zero address indicates no pending upgrade proposal
     */
    address proposalImplementation;

    /**
     * @notice Timestamp after which the implementation upgrade can be accepted
     * @dev Must be >= current timestamp to call acceptImplementation()
     *      Zero value indicates no pending implementation proposal
     */
    uint256 timeToAcceptImplementation;

    //░▒▓█ EVVM Configuration State ████████████████████████████████████████████████████▓▒░

    /**
     * @notice Deadline for changing the EVVM ID
     * @dev EVVM ID can only be changed within 24 hours of deployment or last change
     *      Prevents unauthorized ID changes after initial configuration period
     */
    uint256 windowTimeToChangeEvvmID;

    /**
     * @notice Core metadata configuration for the EVVM instance
     * @dev Contains:
     *      - EvvmName: Human-readable name of this EVVM instance
     *      - EvvmID: Unique identifier used in signature verification
     *      - principalTokenName/Symbol: Principal token details
     *      - principalTokenAddress: Address representing the Principal Token in balances
     *      - totalSupply: Current total supply of principal token
     *      - eraTokens: Threshold for next reward halving era
     *      - reward: Current reward amount per transaction
     */
    EvvmMetadata evvmMetadata;

    //░▒▓█ Admin Governance State ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Admin address management with time-delayed transitions
     * @dev Contains:
     *      - current: Active admin address with full privileges
     *      - proposal: Proposed new admin (awaiting acceptance)
     *      - timeToAccept: Timestamp when proposal can be accepted
     */
    AddressTypeProposal admin;

    //░▒▓█ Initialization State ████████████████████████████████████████████████████████▓▒░

    /**
     * @notice One-time setup breaker flag for NameService and Treasury configuration
     * @dev Set to FLAG_IS_STAKER (0x01) in constructor, set to 0x00 after setup
     *      Prevents _setupNameServiceAndTreasuryAddress from being called twice
     */
    bytes1 breakerSetupNameServiceAddress;

    //░▒▓█ Staker Registry █████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Registry mapping addresses to their staker status
     * @dev Key: User address
     *      Value: Staker flag (FLAG_IS_STAKER = 0x01 for active stakers)
     *      Stakers receive priority fees and Principal Token rewards for processing transactions
     */
    mapping(address => bytes1) stakerList;

    //░▒▓█ Balance Management ██████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Token balance storage for all users across all tokens
     * @dev Primary balance mapping: user address => token address => balance
     *      Supports Principal Token, ETH (address(0)), and whitelisted ERC20s
     *      All payment operations update these balances
     */
    mapping(address user => mapping(address token => uint256 quantity)) balances;

    //░▒▓█ Nonce Management █████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Sequential nonce tracking for synchronous transactions
     * @dev Nonces must be used in strict sequential order (0, 1, 2, ...)
     *      Provides ordered transaction execution and simpler replay protection
     *      Incremented after each successful sync transaction
     */
    mapping(address user => uint256 nonce) nextSyncUsedNonce;

    /**
     * @notice Flexible nonce tracking for asynchronous transactions
     * @dev Nonces can be used in any order but only once
     *      Provides flexibility for parallel transaction submission
     *      Marked as used (true) after consumption
     */
    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncUsedNonce;

    //░▒▓█ Fisher Bridge State ██████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Sequential nonce for Fisher Bridge cross-chain deposits
     * @dev Tracks deposit operations for cross-chain asset bridging
     *      Ensures ordered processing of bridge deposit transactions
     */
    mapping(address user => uint256 nonce) nextFisherDepositNonce;
}
