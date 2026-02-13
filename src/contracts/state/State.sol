// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/*
  █████████ █████           █████           
 ███▒▒▒▒▒██▒▒███           ▒▒███            
▒███    ▒▒▒███████  ██████ ███████   ██████ 
▒▒████████▒▒▒███▒  ▒▒▒▒▒██▒▒▒███▒   ███▒▒███
 ▒▒▒▒▒▒▒▒███▒███    ███████ ▒███   ▒███████ 
 ███    ▒███▒███ █████▒▒███ ▒███ ██▒███▒▒▒  
▒▒█████████ ▒▒████▒▒████████▒▒█████▒▒██████ 
 ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒                                                                                            

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
                                                             
 * @title State - Central Nonce Coordination and User Validation
 * @author Mate labs
 * @notice Single source of truth for all nonce management
 * @dev Centralized nonce coordinator (sync/async). Atomic signature validation (EIP-191) + nonce consumption. Nonce reservation for services. UserValidator integration. Time-delayed governance (1d).
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    SignatureRecover
} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    StateError as Error
} from "@evvm/testnet-contracts/library/errors/StateError.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
import {
    IUserValidator
} from "@evvm/testnet-contracts/interfaces/IUserValidator.sol";
import {
    Admin
} from "@evvm/testnet-contracts/library/utils/governance/Admin.sol";
import {CAUtils} from "@evvm/testnet-contracts/library/utils/CAUtils.sol";

 
contract State is Admin {
    uint256 private constant DELAY = 1 days;

    Evvm private evvm;

    ProposalStructs.AddressTypeProposal userValidatorAddress;
    ProposalStructs.AddressTypeProposal evvmAddress;

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
        private asyncNonceReservedPointers;

    /**
     * @notice Sequential nonce tracking for synchronous transactions
     * @dev Nonces must be used in strict sequential order (0, 1, 2, ...)
     *      Provides ordered transaction execution and simpler replay protection
     *      Incremented after each successful sync transaction
     */
    mapping(address user => uint256 nonce) private nextSyncNonce;

    /**
     * @notice Initializes State contract with EVVM and admin
     * @dev Sets up the nonce coordinator with EVVM integration
     *
     * Initial Configuration:
     * - Connects to EVVM contract for chain ID verification
     * - Sets initial admin for governance operations
     * - Initializes empty nonce mappings for all users
     *
     * @param _evvmAddress Address of the EVVM core contract
     * @param _initialAdmin Address with administrative privileges
     */
    constructor(
        address _evvmAddress,
        address _initialAdmin
    ) Admin(_initialAdmin) {
        evvm = Evvm(_evvmAddress);
    }

    //🬤🬎🬃Nonce Validation Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Validates signature and consumes nonce atomically
     * @dev Central coordination function for all EVVM transactions
     *
     * Validation Workflow:
     * - Verifies caller is a contract (services only)
     * - Reconstructs EIP-191 signature payload
     * - Recovers signer and validates against user address
     * - Checks user transaction permission via validator
     * - Validates and consumes nonce based on type
     *
     * Nonce Management:
     * - Async: Checks availability/reservation, marks as used
     * - Sync: Validates sequential order, increments counter
     * - Prevents replay attacks through atomic consumption
     *
     * Service Integration:
     * - Called by all EVVM services for transaction validation
     * - Service address becomes part of signature payload
     * - Ensures service-specific nonce reservations are honored
     *
     * Security Features:
     * - Atomic signature validation + nonce consumption
     * - Contract-only caller restriction
     * - UserValidator integration for transaction filtering
     * - Service-specific nonce reservation enforcement
     *
     * @param user Address that signed the transaction
     * @param hashPayload Keccak256 hash of transaction parameters
     * @param nonce Nonce value to validate and consume
     * @param isAsyncExec True for async nonce, false for sync
     * @param signature EIP-191 signature from the user
     */
    function validateAndConsumeNonce(
        address user,
        bytes32 hashPayload,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external {
        address servicePointer = msg.sender;

        if (!CAUtils.verifyIfCA(servicePointer))
            revert Error.MsgSenderIsNotAContract();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvm.getEvvmID(),
                    servicePointer,
                    hashPayload,
                    nonce,
                    isAsyncExec
                ),
                signature
            ) != user
        ) revert Error.InvalidSignature();

        if (!canExecuteUserTransaction(user))
            revert Error.UserCannotExecuteTransaction();

        if (isAsyncExec) {
            bytes1 statusNonce = asyncNonceStatus(user, nonce);
            if (asyncNonceStatus(user, nonce) == 0x01)
                revert Error.AsyncNonceAlreadyUsed();

            if (
                statusNonce == 0x02 &&
                asyncNonceReservedPointers[user][nonce] != servicePointer
            ) revert Error.AsyncNonceIsReservedByAnotherService();

            asyncNonce[user][nonce] = true;
        } else {
            if (nonce != nextSyncNonce[user]) revert Error.SyncNonceMismatch();

            unchecked {
                ++nextSyncNonce[user];
            }
        }
    }

    //🬤🬎🬃Nonce Reservation Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Reserves an async nonce for exclusive service use
     * @dev Allows users to pre-allocate nonces to specific services
     *
     * Reservation System:
     * - Users reserve nonces for specific service addresses
     * - Prevents other services from using reserved nonces
     * - Useful for multi-step or delayed operations
     * - Reservation persists until revoked or nonce is used
     *
     * Use Cases:
     * - Cross-chain operations requiring coordination
     * - Multi-signature workflows with specific executors
     * - Service-specific transaction queues
     * - Preventing front-running by other services
     *
     * Security Features:
     * - User-controlled reservation (msg.sender)
     * - Validates service address is not zero
     * - Prevents double reservation of same nonce
     * - Cannot reserve already-used nonces
     *
     * @param nonce The async nonce value to reserve
     * @param serviceAddress Service contract that can use nonce
     */
    function reserveAsyncNonce(uint256 nonce, address serviceAddress) external {
        if (serviceAddress == address(0)) revert Error.InvalidServiceAddress();
        
        if (asyncNonce[msg.sender][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[msg.sender][nonce] != address(0))
            revert Error.AsyncNonceAlreadyReserved();

        asyncNonceReservedPointers[msg.sender][nonce] = serviceAddress;
    }

    /**
     * @notice Revokes a previously reserved async nonce
     * @dev Allows clearing of nonce reservations for reuse
     *
     * Revocation Process:
     * - Validates nonce has not been used yet
     * - Checks that nonce is currently reserved
     * - Clears the service address reservation
     * - Nonce becomes available for any service
     *
     * Authorization:
     * - Currently callable by anyone (potential security issue)
     * - Should validate msg.sender is user or authorized
     * - Allows cancellation of mistaken reservations
     *
     * Use Cases:
     * - Canceling pending service operations
     * - Correcting accidental reservations
     * - Freeing nonces for different services
     *
     * @param user Address that reserved the nonce
     * @param nonce The async nonce to revoke reservation for
     */
    function revokeAsyncNonce(address user, uint256 nonce) external {
        if (asyncNonce[user][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[user][nonce] == address(0))
            revert Error.AsyncNonceNotReserved();

        asyncNonceReservedPointers[user][nonce] = address(0);
    }

    //🬤🬎🬃UserValidator Management Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Proposes new UserValidator contract address
     * @dev Initiates time-delayed governance for validator changes
     *
     * Governance Process:
     * - Admin proposes new validator contract address
     * - 1-day delay enforced before acceptance
     * - Allows community review of validator changes
     * - Can be canceled before acceptance
     *
     * UserValidator Integration:
     * - Optional contract for transaction filtering
     * - Called during validateAndConsumeNonce execution
     * - Can block specific users from executing transactions
     * - Useful for compliance or security requirements
     *
     * Security Features:
     * - Time-delayed governance (DELAY constant)
     * - Admin-only proposal capability
     * - Cancellation mechanism before activation
     *
     * @param newValidator Address of proposed UserValidator
     */
    function proposeUserValidator(address newValidator) external onlyAdmin {
        userValidatorAddress.proposal = newValidator;
        userValidatorAddress.timeToAccept = block.timestamp + DELAY;
    }

    /**
     * @notice Cancels pending UserValidator proposal
     * @dev Resets proposal state before time-lock expires
     *
     * @custom:access Admin only
     */
    function cancelUserValidatorProposal() external onlyAdmin {
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    /**
     * @notice Accepts UserValidator proposal after time-lock
     * @dev Activates new validator after delay period expires
     *
     * Activation Process:
     * - Validates time-lock period has passed
     * - Sets new validator as current active validator
     * - Clears proposal state
     * - Validator becomes active immediately
     *
     * Impact:
     * - All future transactions checked by new validator
     * - Affects validateAndConsumeNonce behavior
     * - Can block users from executing transactions
     *
     * @custom:access Admin only
     * @custom:timelock Requires DELAY (1 day) to have passed
     */
    function acceptUserValidatorProposal() external onlyAdmin {
        if (block.timestamp < userValidatorAddress.timeToAccept)
            revert Error.ProposalForUserValidatorNotReady();

        userValidatorAddress.current = userValidatorAddress.proposal;
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    //🬤🬎🬃EVVM Address Management Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Proposes new EVVM core contract address
     * @dev Initiates time-delayed governance for EVVM changes
     *
     * Critical Update:
     * - Changes the core EVVM contract State coordinates with
     * - Affects chain ID verification in signatures
     * - 1-day delay for security review
     *
     * Use Cases:
     * - EVVM contract upgrades
     * - Migration to new EVVM deployment
     * - Emergency EVVM contract replacement
     *
     * @param newEvvm Address of proposed EVVM contract
     * @custom:access Admin only
     */
    function proposeEvvmAddress(address newEvvm) external onlyAdmin {
        evvmAddress.proposal = newEvvm;
        evvmAddress.timeToAccept = block.timestamp + DELAY;
    }

    /**
     * @notice Cancels pending EVVM address proposal
     * @dev Resets proposal state before time-lock expires
     *
     * @custom:access Admin only
     */
    function cancelEvvmAddressProposal() external onlyAdmin {
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

    /**
     * @notice Accepts EVVM address proposal after time-lock
     * @dev Activates new EVVM contract after delay expires
     *
     * Activation Process:
     * - Validates time-lock period has passed (1 day)
     * - Updates current EVVM address reference
     * - Reinitializes EVVM contract instance
     * - Clears proposal state
     *
     * Critical Impact:
     * - All signature validations use new EVVM's chain ID
     * - Affects validateAndConsumeNonce operations
     * - Changes EVVM integration point
     *
     * @custom:access Admin only
     * @custom:timelock Requires DELAY (1 day) to have passed
     */
    function acceptEvvmAddressProposal() external onlyAdmin {
        if (block.timestamp < evvmAddress.timeToAccept)
            revert Error.ProposalForEvvmAddressNotReady();

        evvmAddress.current = evvmAddress.proposal;
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;

        evvm = Evvm(evvmAddress.current);
    }

    //🬤🬎🬃View Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Gets service address that reserved an async nonce
     * @dev Returns address(0) if nonce is not reserved
     *
     * @param user Address of the user who owns the nonce
     * @param nonce Async nonce to check reservation for
     * @return Service address that reserved the nonce, or
     *         address(0) if not reserved
     */
    function getAsyncNonceReservation(
        address user,
        uint256 nonce
    ) public view returns (address) {
        return asyncNonceReservedPointers[user][nonce];
    }

    /**
     * @notice Gets comprehensive status of an async nonce
     * @dev Returns byte code indicating nonce state
     *
     * Status Codes:
     * - 0x00: Available (can be used by any service)
     * - 0x01: Used (already consumed, cannot be reused)
     * - 0x02: Reserved (allocated to specific service)
     *
     * @param user Address of the user who owns the nonce
     * @param nonce Async nonce to check status for
     * @return Status code: 0x00 (available), 0x01 (used),
     *         or 0x02 (reserved)
     */
    function asyncNonceStatus(
        address user,
        uint256 nonce
    ) public view returns (bytes1) {
        if (asyncNonce[user][nonce]) {
            return 0x01;
        } else if (asyncNonceReservedPointers[user][nonce] != address(0)) {
            return 0x02;
        } else {
            return 0x00;
        }
    }

    /**
     * @notice Checks if a specific nonce has been used by a user
     * @dev Public view function for external queries and UI integration
     * @param user Address of the user to check
     * @param nonce The nonce value to query
     * @return True if the nonce has been used, false if available
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncNonce[user][nonce];
    }

    /**
     * @notice Gets the current (next expected) nonce for a user
     * @dev Public view function for external queries and transaction preparation
     * @param user Address of the user to query
     * @return The next nonce value that must be used by the user
     */
    function getNextCurrentSyncNonce(
        address user
    ) public view virtual returns (uint256) {
        return nextSyncNonce[user];
    }

    /**
     * @notice Gets EVVM chain ID from current EVVM contract
     * @dev Used for signature payload construction
     *
     * @return EVVM chain identifier for signature validation
     */
    function getEvvmID() public view returns (uint256) {
        return evvm.getEvvmID();
    }

    /**
     * @notice Gets current EVVM contract address
     * @dev Returns active EVVM contract that State coordinates with
     *
     * @return Address of current EVVM core contract
     */
    function getEvvmAddress() public view returns (address) {
        return address(evvm);
    }

    /**
     * @notice Gets full EVVM address proposal details
     * @dev Returns current, proposed address and time-lock info
     *
     * @return Proposal struct with current address, proposed
     *         address, and time to accept
     */
    function getEvvmAddressDetails()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return evvmAddress;
    }

    /**
     * @notice Gets current UserValidator contract address
     * @dev Returns address(0) if no validator is configured
     *
     * @return Address of active UserValidator contract
     */
    function getUserValidatorAddress() public view returns (address) {
        return userValidatorAddress.current;
    }

    /**
     * @notice Gets full UserValidator proposal details
     * @dev Returns current, proposed address and time-lock info
     *
     * @return Proposal struct with current validator address,
     *         proposed address, and time to accept
     */
    function getUserValidatorAddressDetails()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return userValidatorAddress;
    }

    //🬤🬎🬃Internal Functions 🬋🬻🬗🬲🬱🬗🬂🬏🬢🬚🬜🬞🬷🬃🬌🬓🬍🬻🬸🬹🬌🬎🬄🬗

    /**
     * @notice Validates if user can execute transactions
     * @dev Checks with UserValidator if configured, allows all if not
     *
     * Validation Logic:
     * - If no validator configured: Returns true (all allowed)
     * - If validator configured: Delegates to validator.canExecute
     * - Used by validateAndConsumeNonce before nonce consumption
     *
     * Integration:
     * - Called during every transaction validation
     * - Allows external filtering of user transactions
     * - Supports compliance and security requirements
     *
     * @param user Address to check execution permission for
     * @return True if user can execute, false if blocked
     */
    function canExecuteUserTransaction(
        address user
    ) internal view returns (bool) {
        if (userValidatorAddress.current == address(0)) return true;
        return IUserValidator(userValidatorAddress.current).canExecute(user);
    }
}
