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
 * @title EVVM Name Service
 * @author Mate labs
 * @notice Identity and username registration system for the EVVM ecosystem.
 * @dev Manages username registration via a commit-reveal scheme (pre-registration), 
 *      a secondary marketplace for domain trading, and customizable user metadata. 
 *      Integrates with Core.sol for payment processing and uses async nonces for high throughput.
 */
 import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
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
    /// @dev Time delay for accepting proposals (1 day)
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /// @dev Principal Tokens locked in pending marketplace
    uint256 private principalTokenTokenLockedForWithdrawOffers;

    /// @dev Nested mapping: username => offer ID => offer
    mapping(string username => mapping(uint256 id => NameServiceStructs.OfferMetadata))
        private usernameOffers;

    /// @dev Nested mapping: username => key => custom value
    mapping(string username => mapping(uint256 numberKey => string customValue))
        private identityCustomMetadata;

    /// @dev Proposal system for token withdrawal with delay
    ProposalStructs.UintTypeProposal amountToWithdrawTokens;

    /// @dev Proposal system for Core address changes
    ProposalStructs.AddressTypeProposal coreAddress;

    /// @dev Proposal system for admin address changes
    ProposalStructs.AddressTypeProposal admin;

    /// @dev Mapping from username to core metadata
    mapping(string username => NameServiceStructs.IdentityBaseMetadata basicMetadata)
        private identityDetails;

    /// @dev EVVM contract for payment processing
    Core private core;

    /// @dev Restricts function access to current admin only
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    //█ Initialization ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Initializes the NameService with the Core contract and initial administrator.
     * @param _coreAddress The address of the EVVM Core contract.
     * @param _initialOwner The address granted administrative privileges.
     */
    constructor(address _coreAddress, address _initialOwner) {
        coreAddress.current = _coreAddress;
        admin.current = _initialOwner;
        core = Core(_coreAddress);
    }

    //█ Registration Functions ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Commits a username hash to prevent front-running before registration.
     * @dev Part of the commit-reveal scheme. Valid for 30 minutes.
     * @param user The address of the registrant.
     * @param hashPreRegisteredUsername The keccak256 hash of (username + secret).
     * @param originExecutor Optional tx.origin restriction.
     * @param nonce Async nonce for signature verification.
     * @param signature Registrant's authorization signature.
     * @param priorityFeeEvvm Optional priority fee for the executor.
     * @param nonceEvvm Nonce for the Core payment (if fee is paid).
     * @param signatureEvvm Signature for the Core payment (if fee is paid).
     */
    function preRegistrationUsername(
        address user,
        bytes32 hashPreRegisteredUsername,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForPreRegistrationUsername(hashPreRegisteredUsername),
            originExecutor,
            nonce,
            true,
            signature
        );

        if (priorityFeeEvvm > 0)
            requestPay(user, 0, priorityFeeEvvm, nonceEvvm, signatureEvvm);

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

        if (core.isAddressStaker(msg.sender))
            makeCaPay(msg.sender, core.getRewardAmount() + priorityFeeEvvm);
    }

    /**
     * @notice Finalizes username registration by revealing the secret associated with a pre-registration.
     * @dev Validates format, availability, and payment. Grants 1 year of ownership.
     * @param user The address of the registrant.
     * @param username The plain-text username being registered.
     * @param lockNumber The secret used in the pre-registration hash.
     * @param originExecutor Optional tx.origin restriction.
     * @param nonce Async nonce for signature verification.
     * @param signature Registrant's authorization signature.
     * @param priorityFeeEvvm Optional priority fee for the executor.
     * @param nonceEvvm Nonce for the Core payment (registration fee + priority fee).
     * @param signatureEvvm Signature for the Core payment.
     */
    function registrationUsername(
        address user,
        string memory username,
        uint256 lockNumber,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForRegistrationUsername(username, lockNumber),
            originExecutor,
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

        if (core.isAddressStaker(msg.sender))
            makeCaPay(
                msg.sender,
                (50 * core.getRewardAmount()) + priorityFeeEvvm
            );

        delete identityDetails[_key];
    }

    //█ Marketplace Functions ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Places a purchase offer on an existing username.
     * @dev Tokens are locked in the contract. A 0.5% marketplace fee is applied upon successful sale.
     * @param user The address of the offerer.
     * @param username The target username.
     * @param amount Total amount offered (including fee).
     * @param expirationDate When the offer expires.
     * @param originExecutor Optional tx.origin restriction.
     * @param nonce Async nonce for signature verification.
     * @param signature Offerer's authorization signature.
     * @param priorityFeeEvvm Optional priority fee for the executor.
     * @param nonceEvvm Nonce for the Core payment (locks tokens).
     * @param signatureEvvm Signature for the Core payment.
     * @return offerID The unique ID of the created offer.
     */
    function makeOffer(
        address user,
        string memory username,
        uint256 amount,
        uint256 expirationDate,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external returns (uint256 offerID) {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForMakeOffer(username, amount, expirationDate),
            originExecutor,
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

        requestPay(user, amount, priorityFeeEvvm, nonceEvvm, signatureEvvm);

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
            core.getRewardAmount() +
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
     * @notice Withdraws marketplace offer and refunds tokens
     * @dev Can only be called by offer creator or after expire
     *
     * Withdrawal Flow:
     * 1. Validates offer exists and belongs to user
     * 2. Optionally validates expiration date passed
     * 3. Refunds locked tokens to offerer
     * 4. Processes optional priority fee
     * 5. Deletes offer and updates slot count
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes username + offer ID
     * - Prevents replay attacks and double withdrawals
     *
     * Core.sol Integration:
     * - Refund: offer amount via makeTransfer to offerer
     * - Priority fee: via requestPay (if > 0)
     * - Staker reward: 1x reward + priority fee
     * - makeCaPay distributes to caller if staker
     *
     * Token Unlocking:
     * - Decreases principalTokenTokenLockedForWithdrawOffers
     * - Releases both offer amount and marketplace fee
     * - Returns funds to original offerer
     *
     * @param user Address that made original offer
     * @param username Username offer was made for
     * @param offerID Unique identifier of offer to withdraw
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function withdrawOffer(
        address user,
        string memory username,
        uint256 offerID,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForWithdrawOffer(username, offerID),
            originExecutor,
            nonce,
            true,
            signature
        );

        if (usernameOffers[username][offerID].offerer != user)
            revert Error.UserIsNotOwnerOfOffer();

        if (priorityFeeEvvm > 0)
            requestPay(user, 0, priorityFeeEvvm, nonceEvvm, signatureEvvm);

        makeCaPay(user, usernameOffers[username][offerID].amount);

        usernameOffers[username][offerID].offerer = address(0);

        makeCaPay(
            msg.sender,
            core.getRewardAmount() +
                ((usernameOffers[username][offerID].amount * 1) / 796) +
                priorityFeeEvvm
        );

        principalTokenTokenLockedForWithdrawOffers -=
            (usernameOffers[username][offerID].amount) +
            (((usernameOffers[username][offerID].amount * 1) / 199) / 4);
    }

    /**
     * @notice Accepts marketplace offer and transfers ownership
     * @dev Can only be called by current owner before expiration
     *
     * Acceptance Flow:
     * 1. Validates user is current username owner
     * 2. Validates offer exists and not expired
     * 3. Transfers offer amount to seller
     * 4. Transfers ownership to offerer
     * 5. Processes optional priority fee
     * 6. Deletes offer and unlocks tokens
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes username + offer ID
     * - Prevents replay attacks and double acceptance
     *
     * Core.sol Integration:
     * - Payment: offer amount via makeCaPay to seller
     * - Priority fee: via requestPay (if > 0)
     * - Fee Distribution:
     *   * 99.5% to seller (locked amount)
     *   * 0.5% + reward to staker (if applicable)
     * - makeCaPay transfers from locked funds
     *
     * Ownership Transfer:
     * - Changes identityDetails[username].owner
     * - Preserves all metadata and expiration
     * - Transfers all custom metadata slots
     *
     * Token Unlocking:
     * - Decreases principalTokenTokenLockedForWithdrawOffers
     * - Releases offer amount + marketplace fee
     * - Distributes to seller and staker
     *
     * @param user Address of current username owner
     * @param username Username being sold
     * @param offerID Unique identifier of offer to accept
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function acceptOffer(
        address user,
        string memory username,
        uint256 offerID,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForAcceptOffer(username, offerID),
            originExecutor,
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
            requestPay(user, 0, priorityFeeEvvm, nonceEvvm, signatureEvvm);
        }

        makeCaPay(user, usernameOffers[username][offerID].amount);

        identityDetails[username].owner = usernameOffers[username][offerID]
            .offerer;

        usernameOffers[username][offerID].offerer = address(0);

        if (core.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (core.getRewardAmount()) +
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
     * @notice Renews username registration for another year
     * @dev Dynamic pricing based on timing and market demand
     *
     * Pricing Rules:
     * - Free: Renewed within grace period after expiration
     * - Variable: Based on highest active offer (min 500 PT)
     * - Fixed: 500,000 PT if renewed >1 year early
     * - Can renew up to 100 years in advance
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes username only
     * - Prevents replay attacks
     *
     * Core.sol Integration:
     * - Payment: seePriceToRenew calculates cost
     * - Paid through requestPay (locks tokens)
     * - Staker reward: 1x reward + 50% of price + fee
     * - makeCaPay distributes rewards
     *
     * Renewal Logic:
     * - Extends expirationDate by 366 days
     * - Preserves ownership and all metadata
     * - Cannot exceed 100 years (36500 days)
     *
     * @param user Address of username owner
     * @param username Username to renew
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function renewUsername(
        address user,
        string memory username,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForRenewUsername(username),
            originExecutor,
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
            signatureEvvm
        );

        if (core.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                core.getRewardAmount() +
                    ((priceOfRenew * 50) / 100) +
                    priorityFeeEvvm
            );
        }

        identityDetails[username].expirationDate += 366 days;
    }

    //█ Metadata Functions ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Adds custom metadata to username using schema format
     * @dev Metadata format: [schema]:[subschema]>[value]
     *
     * Standard Format Examples:
     * - memberOf:>EVVM
     * - socialMedia:x>jistro (Twitter/X handle)
     * - email:dev>jistro[at]evvm.org (dev email)
     * - email:callme>contact[at]jistro.xyz (contact)
     *
     * Schema Guidelines:
     * - Based on https://schema.org/docs/schemas.html
     * - ':' separates schema from subschema
     * - '>' separates metadata from value
     * - Pad spaces if schema/subschema < 5 chars
     * - Use "socialMedia" for social networks
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes identity + value
     * - Prevents replay attacks
     *
     * Core.sol Integration:
     * - Payment: 10x EVVM reward amount
     * - Paid through requestPay (locks tokens)
     * - Staker reward: 5x reward + priority fee
     * - makeCaPay distributes rewards
     *
     * Slot Management:
     * - Increments customMetadataMaxSlots
     * - Each slot holds one metadata entry
     * - No limit on number of slots
     *
     * @param user Address of username owner
     * @param identity Username to add metadata to
     * @param value Metadata string following format
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function addCustomMetadata(
        address user,
        string memory identity,
        string memory value,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForAddCustomMetadata(identity, value),
            originExecutor,
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
            signatureEvvm
        );

        if (core.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * core.getRewardAmount()) +
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
     * @notice Removes specific custom metadata entry by key
     * @dev Shifts all subsequent entries to fill gap
     *
     * Removal Process:
     * 1. Validates user owns username
     * 2. Validates key exists in metadata slots
     * 3. Deletes entry at key position
     * 4. Shifts all entries after key down by 1
     * 5. Decrements customMetadataMaxSlots
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes identity + key
     * - Prevents replay attacks
     *
     * Core.sol Integration:
     * - Payment: 10x EVVM reward amount
     * - Paid through requestPay (locks tokens)
     * - Staker reward: 5x reward + priority fee
     * - makeCaPay distributes rewards
     *
     * Array Reordering:
     * - Shifts entries from key+1 to maxSlots
     * - Maintains continuous slot indexing
     * - No gaps in metadata array
     *
     * @param user Address of username owner
     * @param identity Username to remove metadata from
     * @param key Index of metadata entry to remove
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function removeCustomMetadata(
        address user,
        string memory identity,
        uint256 key,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForRemoveCustomMetadata(identity, key),
            originExecutor,
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

        if (core.isAddressStaker(msg.sender))
            makeCaPay(
                msg.sender,
                (5 * core.getRewardAmount()) + priorityFeeEvvm
            );
    }

    /**
     * @notice Removes all custom metadata entries for username
     * @dev More gas-efficient than removing individually
     *
     * Flush Process:
     * 1. Validates user owns username
     * 2. Validates metadata slots exist (not empty)
     * 3. Calculates cost based on slot count
     * 4. Deletes all metadata entries in loop
     * 5. Resets customMetadataMaxSlots to 0
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes identity only
     * - Prevents replay attacks
     *
     * Core.sol Integration:
     * - Payment: getPriceToFlushCustomMetadata (per slot)
     * - Cost: 10x EVVM reward per metadata entry
     * - Paid through requestPay (locks tokens)
     * - Staker reward: 5x reward per slot + priority
     * - makeCaPay distributes batch rewards
     *
     * Efficiency:
     * - Single transaction for all metadata
     * - Batch pricing for multiple entries
     * - Cheaper than calling removeCustomMetadata N times
     *
     * @param user Address of username owner
     * @param identity Username to flush all metadata from
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function flushCustomMetadata(
        address user,
        string memory identity,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForFlushCustomMetadata(identity),
            originExecutor,
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
            signatureEvvm
        );

        for (
            uint256 i = 0;
            i < identityDetails[identity].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[identity][i];
        }

        if (core.isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                ((5 * core.getRewardAmount()) *
                    identityDetails[identity].customMetadataMaxSlots) +
                    priorityFeeEvvm
            );
        }

        identityDetails[identity].customMetadataMaxSlots = 0;
    }

    /**
     * @notice Completely removes username and all data
     * @dev Deletes username, metadata, makes available for
     * re-registration
     *
     * Flush Process:
     * 1. Validates user owns username
     * 2. Validates not expired (must be active)
     * 3. Validates is actual username (not temp hash)
     * 4. Calculates cost based on metadata + username
     * 5. Deletes all metadata entries
     * 6. Resets username to default state
     * 7. Preserves offerMaxSlots history
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes username only
     * - Prevents replay attacks
     *
     * Core.sol Integration:
     * - Payment: getPriceToFlushUsername
     * - Cost: Base + (10x reward per metadata slot)
     * - Paid through requestPay (locks tokens)
     * - Staker reward: 5x reward per slot + priority
     * - makeCaPay distributes to caller
     *
     * Cleanup:
     * - Deletes all custom metadata slots
     * - Sets owner to address(0)
     * - Sets expirationDate to 0
     * - Resets customMetadataMaxSlots to 0
     * - Keeps offerMaxSlots for history
     * - Sets flagNotAUsername to 0x00
     * - Username becomes available for re-registration
     *
     * @param user Address of username owner
     * @param username Username to completely remove
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFeeEvvm Priority fee for faster processing
     * @param nonceEvvm Nonce for EVVM payment transaction
     * @param signatureEvvm Signature for EVVM payment
     */
    function flushUsername(
        address user,
        string memory username,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForFlushUsername(username),
            originExecutor,
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
            ((5 * core.getRewardAmount()) *
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

    //█ Administrative Functions ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Proposes new admin address with 1-day delay
     * @dev Time-delayed governance system for admin changes
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
            core.getBalance(address(this), core.getPrincipalTokenAddress()) -
                (5083 +
                    core.getRewardAmount() +
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

        coreAddress.proposal = _newEvvmAddress;
        coreAddress.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the pending EVVM address change proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelChangeEvvmAddress() public onlyAdmin {
        coreAddress.proposal = address(0);
        coreAddress.timeToAccept = 0;
    }

    /**
     * @notice Executes the approved EVVM address change
     * @dev Can only be called after the time delay has passed
     */
    function acceptChangeEvvmAddress() public onlyAdmin {
        if (block.timestamp < coreAddress.timeToAccept)
            revert Error.LockTimeNotExpired();

        coreAddress = ProposalStructs.AddressTypeProposal({
            current: coreAddress.proposal,
            proposal: address(0),
            timeToAccept: 0
        });

        core = Core(coreAddress.current);
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
     * @param signature Signature authorizing the payment
     * @dev all evvm nonce execution are async (true)
     */
    function requestPay(
        address user,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bytes memory signature
    ) internal {
        core.pay(
            user,
            address(this),
            "",
            core.getPrincipalTokenAddress(),
            amount,
            priorityFee,
            address(this),
            nonce,
            true,
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
        core.caPay(user, core.getPrincipalTokenAddress(), amount);
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
                uint256 principalTokenReward = core.getRewardAmount();

                price = ((price * 5) / 1000) > (500000 * principalTokenReward)
                    ? (500000 * principalTokenReward)
                    : ((price * 5) / 1000);
            }
        } else {
            price = 500_000 * core.getRewardAmount();
        }
    }

    /**
     * @notice Gets the current price to add custom metadata to a username
     * @dev Price is dynamic based on current EVVM reward amount
     * @return price Cost in Principal Tokens (10x current reward amount)
     */
    function getPriceToAddCustomMetadata() public view returns (uint256 price) {
        price = 10 * core.getRewardAmount();
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
        price = 10 * core.getRewardAmount();
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
            (10 * core.getRewardAmount()) *
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
            ((10 * core.getRewardAmount()) *
                identityDetails[_identity].customMetadataMaxSlots) +
            core.getRewardAmount();
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
                : core.getRewardAmount() * 100;
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
        return core.getEvvmID();
    }

    /**
     * @notice Gets the current EVVM contract address
     * @dev Returns the address of the EVVM contract used for payment processing
     * @return The current EVVM contract address
     */
    function getCoreAddress() public view returns (address) {
        return coreAddress.current;
    }

    /**
     * @notice Gets complete EVVM address information including pending proposals
     * @dev Returns current EVVM address, proposed address, and proposal acceptance deadline
     * @return currentEvvmAddress Current EVVM contract address
     * @return proposalEvvmAddress Proposed new EVVM address (if any)
     * @return timeToAcceptEvvmAddress Timestamp when proposal can be accepted
     */
    function getCoreAddressFullDetails()
        public
        view
        returns (
            address currentEvvmAddress,
            address proposalEvvmAddress,
            uint256 timeToAcceptEvvmAddress
        )
    {
        return (
            coreAddress.current,
            coreAddress.proposal,
            coreAddress.timeToAccept
        );
    }
}
