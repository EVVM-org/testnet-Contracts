// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 * @title CoreStorage - Storage Layout for EVVM Core
 * @author Mate labs
 * @notice Storage layout for Core.sol proxy pattern
 * @dev Storage layout for upgradeable Core.sol. 
 *      Constants, 
 *      external addresses (State, NameService, Treasury, Staking), 
 *      governance, 
 *      balance management, 
 *      configuration.
 *      Append-only for upgrade safety.
 */

abstract contract CoreStorage {
    //░▒▓█ Constants ██████████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Sentinel for native ETH in token operations
     * @dev address(0) represents native blockchain token
     *      (ETH, MATIC, BNB, etc.)
     */
    address constant ETH_ADDRESS = address(0);

    /**
     * @notice Flag value for registered staker status
     * @dev Used in stakerList mapping to mark addresses
     *      Value 0x01 indicates active staker status
     */
    bytes1 constant FLAG_IS_STAKER = 0x01;

    /**
     * @notice Time delay for admin change proposals
     * @dev 1 day delay for community review of admin changes
     *      Used in proposeAdmin and acceptAdmin functions
     */
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /**
     * @notice Time delay for implementation upgrades
     * @dev 30 day delay for review of critical upgrades
     *      Used in proposeImplementation and accept functions
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
     * @notice Token address pending whitelist approval
     * @dev Part of time-delayed token whitelisting mechanism
     *      Set during prepareWhitelistToken(), cleared on
     *      acceptance
     */
    address whitelistTokenToBeAdded_address;

    /**
     * @notice Liquidity pool for pending whitelist token
     * @dev Validates token has sufficient liquidity before
     *      whitelisting (typically Uniswap V3 pool address)
     */
    address whitelistTokenToBeAdded_pool;

    /**
     * @notice Timestamp when pending token can be accepted
     * @dev After this timestamp, token can be whitelisted
     *      Zero value indicates no pending proposal
     */
    uint256 whitelistTokenToBeAdded_dateToSet;

    //░▒▓█ Proxy Implementation State ██████████████████████████████████████████████████▓▒░

    /**
     * @notice Address of current active implementation
     * @dev All non-matching function calls delegated here
     *      Updated through time-delayed governance process
     * @custom:proxy Slot used by assembly in fallback
     */
    address currentImplementation;

    /**
     * @notice Address of proposed implementation upgrade
     * @dev Set by admin, becomes active after time delay via
     *      acceptImplementation(). Zero = no pending upgrade
     */
    address proposalImplementation;

    /**
     * @notice Timestamp after which upgrade can be accepted
     * @dev Must be >= current timestamp to call
     *      acceptImplementation(). Zero = no pending proposal
     */
    uint256 timeToAcceptImplementation;

    //░▒▓█ EVVM Configuration State ████████████████████████████████████████████████████▓▒░

    /**
     * @notice Deadline for changing the EVVM ID
     * @dev EVVM ID changeable within 24 hours of deployment
     *      or last change. Prevents unauthorized ID changes
     *      after initial configuration period.
     */
    uint256 windowTimeToChangeEvvmID;

    /**
     * @notice Core metadata configuration for EVVM instance
     * @dev Contains:
     *      - EvvmName: Human-readable name of this EVVM
     *      - EvvmID: Unique ID used in signature validation
     *      - principalTokenName/Symbol: Principal token info
     *      - principalTokenAddress: Principal Token address
     *      - totalSupply: Current total supply of token
     *      - eraTokens: Threshold for next reward halving
     *      - reward: Current reward amount per transaction
     *
     * State.sol Integration:
     * - EvvmID used by State.sol for signature validation
     * - Part of EIP-191 signature payload in State
     * - Prevents cross-chain replay attacks
     */
    CoreStructs.EvvmMetadata evvmMetadata;

    //░▒▓█ Admin Governance State ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Admin address management with time-delayed transitions
     * @dev Contains:
     *      - current: Active admin address with full privileges
     *      - proposal: Proposed new admin (awaiting acceptance)
     *      - timeToAccept: Timestamp when proposal can be accepted
     */
    ProposalStructs.AddressTypeProposal admin;

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

    //░▒▓█ Fisher Bridge State ██████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Sequential nonce for Fisher Bridge cross-chain deposits
     * @dev Tracks deposit operations for cross-chain asset bridging
     *      Ensures ordered processing of bridge deposit transactions
     */
    mapping(address user => uint256 nonce) nextFisherDepositNonce;

    //░▒▓█ Nonce State ██████████████████████████████████████████████████████████▓▒░


    ProposalStructs.AddressTypeProposal userValidatorAddress;


    /**
     * @notice Flexible nonce tracking for asynchronous transactions
     * @dev Nonces can be used in any order but only once
     *      Provides flexibility for parallel transaction submission
     *      Marked as used (true) after consumption
     */
    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncNonce;

    /**
     * @notice Service-specific async nonce reservation system
     * @dev Maps user address to nonce to reserved service address
     *      Allows services to reserve nonces before execution
     *      Prevents conflicts between competing services
     */
    mapping(address user => mapping(uint256 nonce => address serviceReserved))
         asyncNonceReservedPointers;

    /**
     * @notice Sequential nonce tracking for synchronous transactions
     * @dev Nonces must be used in strict sequential order (0, 1, 2, ...)
     *      Provides ordered transaction execution and simpler replay protection
     *      Incremented after each successful sync transaction
     */
    mapping(address user => uint256 nonce)  nextSyncNonce;
}
