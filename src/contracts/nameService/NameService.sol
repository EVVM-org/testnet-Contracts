// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 _   _                            
| \ | |                           
|  \| | __ _ _ __ ___   ___       
| . ` |/ _` | '_ ` _ \ / _ \      
| |\  | (_| | | | | | |  __/      
\_| \_/\__,_|_| |_| |_|\___|      
                                  
                                  
 _____                 _          
/  ___|               (_)         
\ `--.  ___ _ ____   ___  ___ ___ 
 `--. \/ _ | '__\ \ / | |/ __/ _ \
/\__/ |  __| |   \ V /| | (_|  __/
\____/ \___|_|    \_/ |_|\___\___|
                                  

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 *
 * @title EVVM Name Service Contract
 * @author Mate labs
 * @notice This contract manages username registration and domain name services for the EVVM ecosystem
 * @dev Provides a comprehensive domain name system with features including:
 *
 * Core Features:
 * - Username registration with pre-registration protection against front-running
 * - Custom metadata management with schema-based data storage
 * - Username trading system with offers and marketplace functionality
 * - Renewal system with dynamic pricing based on market demand
 * - Time-delayed governance for administrative functions
 *
 * Registration Process:
 * 1. Pre-register: Commit to a username hash to prevent front-running
 * 2. Register: Reveal the username and complete registration within 30 minutes
 * 3. Manage: Add custom metadata, handle offers, and renew as needed
 *
 * Security Features:
 * - Signature verification for all operations
 * - Nonce-based replay protection
 * - Time-locked administrative changes
 * - Integration with EVVM core for secure payments
 *
 * Economic Model:
 * - Registration costs 100x EVVM reward amount
 * - Custom metadata operations cost 10x EVVM reward amount
 * - Renewal pricing varies based on market demand and timing
 * - Marketplace takes 0.5% fee on username sales
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {State} from "@evvm/testnet-contracts/contracts/state/State.sol";
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/GovernanceUtils.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    NameServiceError as Error
} from "@evvm/testnet-contracts/library/errors/NameServiceError.sol";
import {
    NameServiceHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/NameServiceHashUtils.sol";
import {
    IdentityValidation
} from "@evvm/testnet-contracts/contracts/nameService/lib/IdentityValidation.sol";

contract NameService {
    /// @dev Time delay constant for accepting proposals
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /// @dev Amount of Principal Tokens locked in pending marketplace offers
    uint256 private principalTokenTokenLockedForWithdrawOffers;

    /// @dev Nested mapping: username => offer ID => offer details
    mapping(string username => mapping(uint256 id => NameServiceStructs.OfferMetadata))
        private usernameOffers;

    /// @dev Nested mapping: username => metadata key => custom value string
    mapping(string username => mapping(uint256 numberKey => string customValue))
        private identityCustomMetadata;

    /// @dev Proposal system for token withdrawal amounts with time delay
    ProposalStructs.UintTypeProposal amountToWithdrawTokens;

    /// @dev Proposal system for EVVM contract address changes with time delay
    ProposalStructs.AddressTypeProposal evvmAddress;

    ProposalStructs.AddressTypeProposal stateAddress;

    /// @dev Proposal system for admin address changes with time delay
    ProposalStructs.AddressTypeProposal admin;

    /// @dev Mapping from username to its core metadata and registration details
    mapping(string username => NameServiceStructs.IdentityBaseMetadata basicMetadata)
        private identityDetails;

    /// @dev Instance of the EVVM core contract for payment processing and token operations
    Evvm private evvm;

    State private state;

    /// @dev Restricts function access to the current admin address only
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    /**
     * @notice Initializes the NameService contract
     * @dev Sets up the EVVM integration and initial admin
     * @param _evvmAddress Address of the EVVM core contract for payment processing
     * @param _initialOwner Address that will have admin privileges
     */
    constructor(
        address _evvmAddress,
        address _stateAddress,
        address _initialOwner
    ) {
        evvmAddress.current = _evvmAddress;
        admin.current = _initialOwner;
        stateAddress.current = _stateAddress;
        evvm = Evvm(_evvmAddress);
        state = State(_stateAddress);
    }

    /**
     * @notice Pre-registers a username hash to prevent front-running attacks
     * @dev Creates a temporary reservation that can be registered 30 minutes later
     * @param user Address of the user making the pre-registration
     * @param hashPreRegisteredUsername Keccak256 hash of username + random number
     * @param nonce Asynchronous nonce for replay protection
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function preRegistrationUsername(
        address user,
        bytes32 hashPreRegisteredUsername,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForPreRegistrationUsername(hashPreRegisteredUsername),
            nonce,
            true,
            signature
        );

        if (priorityFeeEvvm > 0)
            requestPay(
                user,
                0,
                priorityFeeEvvm,
                nonceEvvm,
                isAsyncExecEvvm,
                signatureEvvm
            );

        identityDetails[
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(hashPreRegisteredUsername)
            )
        ] = NameServiceStructs.IdentityBaseMetadata({
            owner: user,
            expirationDate: block.timestamp + 30 minutes,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x01
        });

        if (evvm.isAddressStaker(msg.sender))
            makeCaPay(msg.sender, evvm.getRewardAmount() + priorityFeeEvvm);
    }

    /**
     * @notice Completes username registration using a pre-registration commitment
     * @dev Must be called after the pre-registration period (30 minutes) has reached
     * @param user Address of the user completing the registration
     * @param username The actual username being registered (revealed from hash)
     * @param lockNumber Random number used in the pre-registration hash
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function registrationUsername(
        address user,
        string memory username,
        uint256 lockNumber,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForRegistrationUsername(username, lockNumber),
            nonce,
            true,
            signature
        );

        if (
            admin.current != user &&
            !IdentityValidation.isValidUsername(username)
        ) revert Error.InvalidUsername();

        if (!isUsernameAvailable(username))
            revert Error.UsernameAlreadyRegistered();

        requestPay(
            user,
            getPriceOfRegistration(username),
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        string memory _key = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(hashUsername(username, lockNumber))
        );

        if (
            identityDetails[_key].owner != user ||
            identityDetails[_key].expirationDate > block.timestamp
        ) revert Error.PreRegistrationNotValid();

        identityDetails[username] = NameServiceStructs.IdentityBaseMetadata({
            owner: user,
            expirationDate: block.timestamp + 366 days,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x00
        });

        if (evvm.isAddressStaker(msg.sender))
            makeCaPay(
                msg.sender,
                (50 * evvm.getRewardAmount()) + priorityFeeEvvm
            );

        delete identityDetails[_key];
    }

    /**
     * @notice Creates a marketplace offer to purchase a username
     * @dev Locks the offer amount in the contract until withdrawn or accepted
     * @param user Address making the offer
     * @param username Target username for the offer
     * @param expirationDate Timestamp when the offer expires
     * @param amount Amount being offered in Principal Tokens
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     * @return offerID Unique identifier for the created offer
     */
    function makeOffer(
        address user,
        string memory username,
        uint256 amount,
        uint256 expirationDate,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external returns (uint256 offerID) {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForMakeOffer(username, amount, expirationDate),
            nonce,
            true,
            signature
        );

        if (
            identityDetails[username].flagNotAUsername == 0x01 ||
            !verifyIfIdentityExists(username)
        ) revert Error.InvalidUsername();

        if (expirationDate <= block.timestamp)
            revert Error.CannotBeBeforeCurrentTime();

        if (amount == 0) revert Error.AmountMustBeGreaterThanZero();

        requestPay(
            user,
            amount,
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        while (usernameOffers[username][offerID].offerer != address(0))
            offerID++;

        uint256 amountToOffer = ((amount * 995) / 1000);

        usernameOffers[username][offerID] = NameServiceStructs.OfferMetadata({
            offerer: user,
            expirationDate: expirationDate,
            amount: amountToOffer
        });

        makeCaPay(
            msg.sender,
            evvm.getRewardAmount() +
                ((amount * 125) / 100_000) +
                priorityFeeEvvm
        );

        principalTokenTokenLockedForWithdrawOffers +=
            amountToOffer +
            (amount / 800);

        if (offerID > identityDetails[username].offerMaxSlots) {
            identityDetails[username].offerMaxSlots++;
        } else if (identityDetails[username].offerMaxSlots == 0) {
            identityDetails[username].offerMaxSlots++;
        }
    }

    /**
     * @notice Withdraws a marketplace offer and refunds the locked tokens
     * @dev Can only be called by the offer creator before expiration
     * @param user Address that made the original offer
     * @param username Username the offer was made for
     * @param offerID Unique identifier of the offer to withdraw
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function withdrawOffer(
        address user,
        string memory username,
        uint256 offerID,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForWithdrawOffer(username, offerID),
            nonce,
            true,
            signature
        );

        if (usernameOffers[username][offerID].offerer != user)
            revert Error.UserIsNotOwnerOfOffer();

        if (priorityFeeEvvm > 0)
            requestPay(
                user,
                0,
                priorityFeeEvvm,
                nonceEvvm,
                isAsyncExecEvvm,
                signatureEvvm
            );

        makeCaPay(user, usernameOffers[username][offerID].amount);

        usernameOffers[username][offerID].offerer = address(0);

        makeCaPay(
            msg.sender,
            evvm.getRewardAmount() +
                ((usernameOffers[username][offerID].amount * 1) / 796) +
                priorityFeeEvvm
        );

        principalTokenTokenLockedForWithdrawOffers -=
            (usernameOffers[username][offerID].amount) +
            (((usernameOffers[username][offerID].amount * 1) / 199) / 4);
    }

    /**
     * @notice Accepts a marketplace offer and transfers username ownership
     * @dev Can only be called by the current username owner before offer expiration
     * @param user Address of the current username owner
     * @param username Username being sold
     * @param offerID Unique identifier of the offer to accept
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function acceptOffer(
        address user,
        string memory username,
        uint256 offerID,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForAcceptOffer(username, offerID),
            nonce,
            true,
            signature
        );

        if (identityDetails[username].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (
            usernameOffers[username][offerID].offerer == address(0) ||
            usernameOffers[username][offerID].expirationDate < block.timestamp
        ) revert Error.OfferInactive();

        if (priorityFeeEvvm > 0) {
            requestPay(
                user,
                0,
                priorityFeeEvvm,
                nonceEvvm,
                isAsyncExecEvvm,
                signatureEvvm
            );
        }

        makeCaPay(user, usernameOffers[username][offerID].amount);

        identityDetails[username].owner = usernameOffers[username][offerID]
            .offerer;

        usernameOffers[username][offerID].offerer = address(0);

        if (evvm.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (evvm.getRewardAmount()) +
                    (((usernameOffers[username][offerID].amount * 1) / 199) /
                        4) +
                    priorityFeeEvvm
            );
        }

        principalTokenTokenLockedForWithdrawOffers -=
            (usernameOffers[username][offerID].amount) +
            (((usernameOffers[username][offerID].amount * 1) / 199) / 4);
    }

    /**
     * @notice Renews a username registration for another year
     * @dev Pricing varies based on timing and market demand for the username
     *
     * Pricing Rules:
     * - Free renewal if done within 1 year of expiration (limited time offer)
     * - Variable cost based on highest active offer (minimum 500 Principal Token)
     * - Fixed 500,000 Principal Token if renewed more than 1 year before expiration
     * - Can be renewed up to 100 years in advance
     *
     * @param user Address of the username owner
     * @param username Username to renew
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function renewUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForRenewUsername(username),
            nonce,
            true,
            signature
        );

        if (identityDetails[username].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (identityDetails[username].flagNotAUsername == 0x01)
            revert Error.IdentityIsNotAUsername();

        if (
            identityDetails[username].expirationDate >
            block.timestamp + 36500 days
        ) revert Error.RenewalTimeLimitExceeded();

        uint256 priceOfRenew = seePriceToRenew(username);

        requestPay(
            user,
            priceOfRenew,
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        if (evvm.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                evvm.getRewardAmount() +
                    ((priceOfRenew * 50) / 100) +
                    priorityFeeEvvm
            );
        }

        identityDetails[username].expirationDate += 366 days;
    }

    /**
     * @notice Adds custom metadata to a username following a standardized schema format
     * @dev Metadata follows format: [schema]:[subschema]>[value]
     *
     * Standard Format Examples:
     * - memberOf:>EVVM
     * - socialMedia:x>jistro (Twitter/X handle)
     * - email:dev>jistro[at]evvm.org (development email)
     * - email:callme>contact[at]jistro.xyz (contact email)
     *
     * Schema Guidelines:
     * - Based on https://schema.org/docs/schemas.html
     * - ':' separates schema from subschema
     * - '>' separates metadata from value
     * - Pad with spaces if schema/subschema < 5 characters
     * - Use "socialMedia" for social networks with network name as subschema
     *
     * @param user Address of the username owner
     * @param identity Username to add metadata to
     * @param value Metadata string following the standardized format
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function addCustomMetadata(
        address user,
        string memory identity,
        string memory value,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForAddCustomMetadata(identity, value),
            nonce,
            true,
            signature
        );

        if (identityDetails[identity].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (bytes(value).length == 0) revert Error.EmptyCustomMetadata();

        requestPay(
            user,
            getPriceToAddCustomMetadata(),
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        if (evvm.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * evvm.getRewardAmount()) +
                    ((getPriceToAddCustomMetadata() * 50) / 100) +
                    priorityFeeEvvm
            );
        }

        identityCustomMetadata[identity][
            identityDetails[identity].customMetadataMaxSlots
        ] = value;

        identityDetails[identity].customMetadataMaxSlots++;
    }

    /**
     * @notice Removes a specific custom metadata entry by key and reorders the array
     * @dev Shifts all subsequent metadata entries to fill the gap after removal
     * @param user Address of the username owner
     * @param identity Username to remove metadata from
     * @param key Index of the metadata entry to remove
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function removeCustomMetadata(
        address user,
        string memory identity,
        uint256 key,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForRemoveCustomMetadata(identity, key),
            nonce,
            true,
            signature
        );

        if (identityDetails[identity].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (identityDetails[identity].customMetadataMaxSlots <= key)
            revert Error.InvalidKey();

        requestPay(
            user,
            getPriceToRemoveCustomMetadata(),
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        if (identityDetails[identity].customMetadataMaxSlots == key) {
            delete identityCustomMetadata[identity][key];
        } else {
            for (
                uint256 i = key;
                i < identityDetails[identity].customMetadataMaxSlots;
                i++
            ) {
                identityCustomMetadata[identity][i] = identityCustomMetadata[
                    identity
                ][i + 1];
            }
            delete identityCustomMetadata[identity][
                identityDetails[identity].customMetadataMaxSlots
            ];
        }

        identityDetails[identity].customMetadataMaxSlots--;

        if (evvm.isAddressStaker(msg.sender))
            makeCaPay(
                msg.sender,
                (5 * evvm.getRewardAmount()) + priorityFeeEvvm
            );
    }

    /**
     * @notice Removes all custom metadata entries for a username
     * @dev More gas-efficient than removing entries individually
     * @param user Address of the username owner
     * @param identity Username to flush all metadata from
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function flushCustomMetadata(
        address user,
        string memory identity,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForFlushCustomMetadata(identity),
            nonce,
            true,
            signature
        );

        if (identityDetails[identity].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (identityDetails[identity].customMetadataMaxSlots == 0)
            revert Error.EmptyCustomMetadata();

        requestPay(
            user,
            getPriceToFlushCustomMetadata(identity),
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        for (
            uint256 i = 0;
            i < identityDetails[identity].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[identity][i];
        }

        if (evvm.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                ((5 * evvm.getRewardAmount()) *
                    identityDetails[identity].customMetadataMaxSlots) +
                    priorityFeeEvvm
            );
        }

        identityDetails[identity].customMetadataMaxSlots = 0;
    }

    /**
     * @notice Completely removes a username registration and all associated data
     * @dev Deletes the username, all custom metadata, and makes it available for re-registration
     * @param user Address of the username owner
     * @param username Username to completely remove from the system
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFeeEvvm Priority fee for faster transaction processing
     * @param nonceEvvm Nonce for the EVVM payment transaction
     * @param isAsyncExecEvvm True for async payment, false for sync payment
     * @param signatureEvvm Signature for the EVVM payment transaction
     */
    function flushUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForFlushUsername(username),
            nonce,
            true,
            signature
        );

        if (identityDetails[username].owner != user)
            revert Error.UserIsNotOwnerOfIdentity();

        if (block.timestamp >= identityDetails[username].expirationDate)
            revert Error.OwnershipExpired();

        if (identityDetails[username].flagNotAUsername == 0x01)
            revert Error.IdentityIsNotAUsername();

        requestPay(
            user,
            getPriceToFlushUsername(username),
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        for (
            uint256 i = 0;
            i < identityDetails[username].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[username][i];
        }

        makeCaPay(
            msg.sender,
            ((5 * evvm.getRewardAmount()) *
                identityDetails[username].customMetadataMaxSlots) +
                priorityFeeEvvm
        );

        identityDetails[username] = NameServiceStructs.IdentityBaseMetadata({
            owner: address(0),
            expirationDate: 0,
            customMetadataMaxSlots: 0,
            offerMaxSlots: identityDetails[username].offerMaxSlots,
            flagNotAUsername: 0x00
        });
    }

    //█ Administrative Functions with Time-Delayed Governance ████████████████████████████████████

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _adminToPropose Address of the proposed new admin
     */
    function proposeAdmin(address _adminToPropose) public onlyAdmin {
        if (_adminToPropose == address(0) || _adminToPropose == admin.current)
            revert Error.InvalidAdminProposal();

        admin.proposal = _adminToPropose;
        admin.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the current admin proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelProposeAdmin() public onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts the admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay has passed
     */
    function acceptProposeAdmin() public {
        if (admin.proposal != msg.sender)
            revert Error.SenderIsNotProposedAdmin();

        if (block.timestamp < admin.timeToAccept)
            revert Error.LockTimeNotExpired();

        admin = ProposalStructs.AddressTypeProposal({
            current: admin.proposal,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    /**
     * @notice Proposes to withdraw Principal Tokens from the contract
     * @dev Amount must be available after reserving funds for operations and locked offers
     * @param _amount Amount of Principal Tokens to withdraw
     */
    function proposeWithdrawPrincipalTokens(uint256 _amount) public onlyAdmin {
        if (
            evvm.getBalance(address(this), evvm.getPrincipalTokenAddress()) -
                (5083 +
                    evvm.getRewardAmount() +
                    principalTokenTokenLockedForWithdrawOffers) <
            _amount ||
            _amount == 0
        ) {
            revert Error.InvalidWithdrawAmount();
        }

        amountToWithdrawTokens.proposal = _amount;
        amountToWithdrawTokens.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the pending token withdrawal proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelWithdrawPrincipalTokens() public onlyAdmin {
        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    /**
     * @notice Executes the approved token withdrawal
     * @dev Can only be called after the time delay has passed
     */
    function claimWithdrawPrincipalTokens() public onlyAdmin {
        if (block.timestamp < amountToWithdrawTokens.timeToAccept)
            revert Error.LockTimeNotExpired();

        makeCaPay(admin.current, amountToWithdrawTokens.proposal);

        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    /**
     * @notice Proposes to change the EVVM contract address
     * @dev Critical function that affects payment processing integration
     * @param _newEvvmAddress Address of the new EVVM contract
     */
    function proposeChangeEvvmAddress(
        address _newEvvmAddress
    ) public onlyAdmin {
        if (_newEvvmAddress == address(0)) revert Error.InvalidEvvmAddress();

        evvmAddress.proposal = _newEvvmAddress;
        evvmAddress.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the pending EVVM address change proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelChangeEvvmAddress() public onlyAdmin {
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

    /**
     * @notice Executes the approved EVVM address change
     * @dev Can only be called after the time delay has passed
     */
    function acceptChangeEvvmAddress() public onlyAdmin {
        if (block.timestamp < evvmAddress.timeToAccept)
            revert Error.LockTimeNotExpired();

        evvmAddress = ProposalStructs.AddressTypeProposal({
            current: evvmAddress.proposal,
            proposal: address(0),
            timeToAccept: 0
        });

        evvm = Evvm(evvmAddress.current);
    }

    //█ Utility Functions ████████████████████████████████████████████████████████████████████████

    //█ EVVM Payment Integration ██████████████████████████████████████████████

    /**
     * @notice Internal function to handle payments through the EVVM contract
     * @dev Supports both synchronous and asynchronous payment modes
     * @param user Address making the payment
     * @param amount Amount to pay in Principal Tokens
     * @param priorityFee Additional priority fee for faster processing
     * @param nonce Nonce for the EVVM transaction
     * @param isAsyncExec True for async payment, false for sync payment
     * @param signature Signature authorizing the payment
     */
    function requestPay(
        address user,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) internal {
        evvm.pay(
            user,
            address(this),
            "",
            evvm.getPrincipalTokenAddress(),
            amount,
            priorityFee,
            address(this),
            nonce,
            isAsyncExec,
            signature
        );
    }

    /**
     * @notice Internal function to distribute Principal Tokens to users
     * @dev Calls the EVVM contract's caPay function for token distribution
     * @param user Address to receive the tokens
     * @param amount Amount of Principal Tokens to distribute
     */
    function makeCaPay(address user, uint256 amount) internal {
        evvm.caPay(user, evvm.getPrincipalTokenAddress(), amount);
    }

    //█ Username Hashing Functions ███████████████████████████████████████████████████████████████████

    /**
     * @notice Creates a hash of username and random number for pre-registration
     * @dev Used in the commit-reveal scheme to prevent front-running attacks
     * @param _username The username to hash
     * @param _randomNumber Random number to add entropy
     * @return Hash of the username and random number
     */
    function hashUsername(
        string memory _username,
        uint256 _randomNumber
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_username, _randomNumber));
    }

    //█ View Functions - Public Data Access ██████████████████████████████████████████████████████████

    //█ Service Functions ████████████████████████████████████████████████████████████████

    /**
     * @notice Checks if an identity exists in the system
     * @dev Handles both pre-registrations and actual username registrations
     * @param _identity The identity/username to check
     * @return True if the identity exists and is valid
     */
    function verifyIfIdentityExists(
        string memory _identity
    ) public view returns (bool) {
        if (identityDetails[_identity].flagNotAUsername == 0x01) {
            if (
                identityDetails[_identity].owner == address(0) ||
                identityDetails[_identity].expirationDate != 0
            ) {
                return false;
            } else {
                return true;
            }
        } else {
            if (identityDetails[_identity].expirationDate == 0) {
                return false;
            } else {
                return true;
            }
        }
    }

    /**
     * @notice Strictly verifies if an identity exists and reverts if not found
     * @dev More strict version that reverts instead of returning false
     * @param _username The username to verify
     * @return True if the username exists (will revert if not)
     */
    function strictVerifyIfIdentityExist(
        string memory _username
    ) public view returns (bool) {
        if (identityDetails[_username].flagNotAUsername == 0x01) {
            if (
                identityDetails[_username].owner == address(0) ||
                identityDetails[_username].expirationDate != 0
            ) {
                revert();
            } else {
                return true;
            }
        } else {
            if (identityDetails[_username].expirationDate == 0) {
                revert();
            } else {
                return true;
            }
        }
    }

    /**
     * @notice Gets the owner address of a registered identity
     * @dev Returns the current owner address for any valid identity
     * @param _username The username to query
     * @return Address of the username owner
     */
    function getOwnerOfIdentity(
        string memory _username
    ) public view returns (address) {
        return identityDetails[_username].owner;
    }

    /**
     * @notice Verifies identity exists and returns owner address
     * @dev Combines strict verification with owner lookup in one call
     * @param _username The username to verify and get owner for
     * @return answer Address of the username owner (reverts if username doesn't exist)
     */
    function verifyStrictAndGetOwnerOfIdentity(
        string memory _username
    ) public view returns (address answer) {
        if (strictVerifyIfIdentityExist(_username))
            answer = identityDetails[_username].owner;
    }

    /**
     * @notice Calculates the cost to renew a username registration
     * @dev Pricing varies based on timing and market demand:
     *      - Free if renewed before expiration (within grace period)
     *      - Variable cost based on highest active offer (minimum 500 Principal Token)
     *      - Fixed 500,000 Principal Token if renewed more than 1 year before expiration
     * @param _identity The username to calculate renewal price for
     * @return price The cost in Principal Tokens to renew the username
     */
    function seePriceToRenew(
        string memory _identity
    ) public view returns (uint256 price) {
        if (identityDetails[_identity].expirationDate >= block.timestamp) {
            if (usernameOffers[_identity][0].expirationDate != 0) {
                for (
                    uint256 i = 0;
                    i < identityDetails[_identity].offerMaxSlots;
                    i++
                ) {
                    if (
                        usernameOffers[_identity][i].expirationDate >
                        block.timestamp &&
                        usernameOffers[_identity][i].offerer != address(0)
                    ) {
                        if (usernameOffers[_identity][i].amount > price) {
                            price = usernameOffers[_identity][i].amount;
                        }
                    }
                }
            }
            if (price == 0) {
                price = 500 * 10 ** 18;
            } else {
                uint256 principalTokenReward = evvm.getRewardAmount();

                price = ((price * 5) / 1000) > (500000 * principalTokenReward)
                    ? (500000 * principalTokenReward)
                    : ((price * 5) / 1000);
            }
        } else {
            price = 500_000 * evvm.getRewardAmount();
        }
    }

    /**
     * @notice Gets the current price to add custom metadata to a username
     * @dev Price is dynamic based on current EVVM reward amount
     * @return price Cost in Principal Tokens (10x current reward amount)
     */
    function getPriceToAddCustomMetadata() public view returns (uint256 price) {
        price = 10 * evvm.getRewardAmount();
    }

    /**
     * @notice Gets the current price to remove a single custom metadata entry
     * @dev Price is dynamic based on current EVVM reward amount
     * @return price Cost in Principal Tokens (10x current reward amount)
     */
    function getPriceToRemoveCustomMetadata()
        public
        view
        returns (uint256 price)
    {
        price = 10 * evvm.getRewardAmount();
    }

    /**
     * @notice Gets the cost to remove all custom metadata entries from a username
     * @dev Cost scales with the number of metadata entries to remove
     * @param _identity The username to calculate flush cost for
     * @return price Total cost in Principal Tokens (10x reward amount per metadata entry)
     */
    function getPriceToFlushCustomMetadata(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            (10 * evvm.getRewardAmount()) *
            identityDetails[_identity].customMetadataMaxSlots;
    }

    /**
     * @notice Gets the cost to completely remove a username and all its data
     * @dev Includes cost for metadata removal plus base username deletion fee
     * @param _identity The username to calculate deletion cost for
     * @return price Total cost in Principal Tokens (metadata flush cost + 1x reward amount)
     */
    function getPriceToFlushUsername(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            ((10 * evvm.getRewardAmount()) *
                identityDetails[_identity].customMetadataMaxSlots) +
            evvm.getRewardAmount();
    }

    //█ Identity Availability Functions ██████████████████████████████████████████████████████████████

    /**
     * @notice Checks if a username is available for registration
     * @dev A username is available if it was never registered or has been expired for 60+ days
     * @param _username The username to check availability for
     * @return True if the username is available for registration
     */
    function isUsernameAvailable(
        string memory _username
    ) public view returns (bool) {
        if (identityDetails[_username].expirationDate == 0) {
            return true;
        } else {
            return
                identityDetails[_username].expirationDate + 60 days <
                block.timestamp;
        }
    }

    /**
     * @notice Gets basic identity information (owner and expiration date)
     * @dev Returns essential metadata for quick identity verification
     * @param _username The username to get basic info for
     * @return Owner address and expiration timestamp
     */
    function getIdentityBasicMetadata(
        string memory _username
    ) public view returns (address, uint256) {
        return (
            identityDetails[_username].owner,
            identityDetails[_username].expirationDate
        );
    }

    /**
     * @notice Gets the number of custom metadata entries for a username
     * @dev Returns the count of metadata slots currently used
     * @param _username The username to count metadata for
     * @return Number of custom metadata entries
     */
    function getAmountOfCustomMetadata(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

    /**
     * @notice Retrieves all custom metadata entries for a username
     * @dev Returns an array containing all metadata strings in order
     * @param _username The username to get metadata for
     * @return Array of all custom metadata strings
     */
    function getFullCustomMetadataOfIdentity(
        string memory _username
    ) public view returns (string[] memory) {
        string[] memory _customMetadata = new string[](
            identityDetails[_username].customMetadataMaxSlots
        );
        for (
            uint256 i = 0;
            i < identityDetails[_username].customMetadataMaxSlots;
            i++
        ) {
            _customMetadata[i] = identityCustomMetadata[_username][i];
        }
        return _customMetadata;
    }

    /**
     * @notice Gets a specific custom metadata entry by index
     * @dev Retrieves metadata at a specific slot position
     * @param _username The username to get metadata from
     * @param _key The index of the metadata entry to retrieve
     * @return The metadata string at the specified index
     */
    function getSingleCustomMetadataOfIdentity(
        string memory _username,
        uint256 _key
    ) public view returns (string memory) {
        return identityCustomMetadata[_username][_key];
    }

    /**
     * @notice Gets the maximum number of metadata slots available for a username
     * @dev Returns the total capacity for custom metadata entries
     * @param _username The username to check metadata capacity for
     * @return Maximum number of metadata slots
     */
    function getCustomMetadataMaxSlotsOfIdentity(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

    //█ Username Marketplace Functions ███████████████████████████████████████████████████████████████

    /**
     * @notice Gets all offers made for a specific username
     * @dev Returns both active and expired offers that haven't been withdrawn
     * @param _username The username to get offers for
     * @return offers Array of all offer metadata structures
     */
    function getOffersOfUsername(
        string memory _username
    ) public view returns (NameServiceStructs.OfferMetadata[] memory offers) {
        offers = new NameServiceStructs.OfferMetadata[](
            identityDetails[_username].offerMaxSlots
        );

        for (uint256 i = 0; i < identityDetails[_username].offerMaxSlots; i++) {
            offers[i] = usernameOffers[_username][i];
        }
    }

    /**
     * @notice Gets a specific offer for a username by offer ID
     * @dev Retrieves detailed information about a particular offer
     * @param _username The username to get the offer from
     * @param _offerID The ID/index of the specific offer
     * @return offer The complete offer metadata structure
     */
    function getSingleOfferOfUsername(
        string memory _username,
        uint256 _offerID
    ) public view returns (NameServiceStructs.OfferMetadata memory offer) {
        return usernameOffers[_username][_offerID];
    }

    /**
     * @notice Counts the total number of offers made for a username
     * @dev Iterates through offers to find the actual count of non-empty slots
     * @param _username The username to count offers for
     * @return length Total number of offers that have been made
     */
    function getLengthOfOffersUsername(
        string memory _username
    ) public view returns (uint256 length) {
        do {
            length++;
        } while (usernameOffers[_username][length].expirationDate != 0);
    }

    /**
     * @notice Gets the expiration date of a username registration
     * @dev Returns the timestamp when the username registration expires
     * @param _identity The username to check expiration for
     * @return The expiration timestamp in seconds since Unix epoch
     */
    function getExpireDateOfIdentity(
        string memory _identity
    ) public view returns (uint256) {
        return identityDetails[_identity].expirationDate;
    }

    /**
     * @notice Gets price to register an username
     * @dev Price is fully dynamic based on existing offers and timing
     *      - If dosnt have offers, price is 100x current EVVM reward amount
     *      - If has offers, price is calculated via seePriceToRenew function
     * @param username The username to get registration price for
     * @return The current registration price in Principal Tokens
     */
    function getPriceOfRegistration(
        string memory username
    ) public view returns (uint256) {
        return
            identityDetails[username].offerMaxSlots > 0
                ? seePriceToRenew(username)
                : evvm.getRewardAmount() * 100;
    }

    //█ Administrative Getters ███████████████████████████████████████████████████████████████████████

    /**
     * @notice Gets the current admin address
     * @dev Returns the address with administrative privileges
     * @return The current admin address
     */
    function getAdmin() public view returns (address) {
        return admin.current;
    }

    /**
     * @notice Gets complete admin information including pending proposals
     * @dev Returns current admin, proposed admin, and proposal acceptance deadline
     * @return currentAdmin Current administrative address
     * @return proposalAdmin Proposed new admin address (if any)
     * @return timeToAcceptAdmin Timestamp when proposal can be accepted
     */
    function getAdminFullDetails()
        public
        view
        returns (
            address currentAdmin,
            address proposalAdmin,
            uint256 timeToAcceptAdmin
        )
    {
        return (admin.current, admin.proposal, admin.timeToAccept);
    }

    /**
     * @notice Gets information about pending token withdrawal proposals
     * @dev Returns proposed withdrawal amount and acceptance deadline
     * @return proposalAmountToWithdrawTokens Proposed withdrawal amount in Principal Tokens
     * @return timeToAcceptAmountToWithdrawTokens Timestamp when proposal can be executed
     */
    function getProposedWithdrawAmountFullDetails()
        public
        view
        returns (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        )
    {
        return (
            amountToWithdrawTokens.proposal,
            amountToWithdrawTokens.timeToAccept
        );
    }

    /**
     * @notice Gets the unique identifier string for this EVVM instance
     * @dev Returns the EvvmID used for distinguishing different EVVM deployments
     * @return Unique EvvmID string
     */
    function getEvvmID() external view returns (uint256) {
        return evvm.getEvvmID();
    }

    /**
     * @notice Gets the current EVVM contract address
     * @dev Returns the address of the EVVM contract used for payment processing
     * @return The current EVVM contract address
     */
    function getEvvmAddress() public view returns (address) {
        return evvmAddress.current;
    }

    /**
     * @notice Gets complete EVVM address information including pending proposals
     * @dev Returns current EVVM address, proposed address, and proposal acceptance deadline
     * @return currentEvvmAddress Current EVVM contract address
     * @return proposalEvvmAddress Proposed new EVVM address (if any)
     * @return timeToAcceptEvvmAddress Timestamp when proposal can be accepted
     */
    function getEvvmAddressFullDetails()
        public
        view
        returns (
            address currentEvvmAddress,
            address proposalEvvmAddress,
            uint256 timeToAcceptEvvmAddress
        )
    {
        return (
            evvmAddress.current,
            evvmAddress.proposal,
            evvmAddress.timeToAccept
        );
    }
}
