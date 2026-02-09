// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title NameServiceStructs
 * @author Mate labs
 * @notice Library of data structures used exclusively by the NameService.sol contract
 * @dev This contract defines the type system for the NameService.sol contract,
 *      providing structured data types for identity management, marketplace operations,
 *      and governance proposals. These structures are not shared with external services.
 *
 * Structure Categories:
 * - Identity Structures: IdentityBaseMetadata for username registration data
 * - Marketplace Structures: OfferMetadata for username trading
 * - Governance Structures: AddressTypeProposal, UintTypeProposal, BoolTypeProposal for time-delayed changes
 *
 * @custom:inheritance This contract is inherited by NameService.sol
 * @custom:scope Exclusive to the NameService.sol contract
 */
library NameServiceStructs {

    //░▒▓█ Identity Management Structures ███████████████████████████████████████████████▓▒░

    /**
     * @notice Core metadata for each registered identity/username
     * @dev Stores essential registration information and ownership details
     *
     * Registration States:
     * - flagNotAUsername = 0x01: Pre-registration (temporary reservation)
     * - flagNotAUsername = 0x00: Full username registration (active identity)
     *
     * Ownership Model:
     * - Owner has full control over the username
     * - Ownership expires at expireDate (renewable up to 100 years)
     * - Can be transferred through marketplace offers
     *
     * @param owner Address that owns this identity/username
     * @param expirationDate Timestamp when the registration expires (renewable)
     * @param customMetadataMaxSlots Number of custom metadata entries stored for this identity
     * @param offerMaxSlots Highest offer ID that has been created for this username
     * @param flagNotAUsername 0x01 for pre-registration, 0x00 for full username
     */
    struct IdentityBaseMetadata {
        address owner;
        uint256 expirationDate;
        uint256 customMetadataMaxSlots;
        uint256 offerMaxSlots;
        bytes1 flagNotAUsername;
    }

    //░▒▓█ Marketplace Structures ███████████████████████████████████████████████████████▓▒░

    /**
     * @notice Metadata for marketplace offers on usernames
     * @dev Represents a locked offer to purchase a username at a specific price
     *
     * Offer Lifecycle:
     * 1. Created: Tokens are locked in contract (after 0.5% marketplace fee deduction)
     * 2. Active: Can be accepted by owner or withdrawn by offerer before expiration
     * 3. Expired/Completed: offerer set to address(0), tokens released
     *
     * Fee Structure:
     * - 0.5% marketplace fee deducted from offer amount
     * - Remaining 99.5% locked for potential acceptance
     * - Additional fees for stakers processing the transaction
     *
     * @param offerer Address that created and can withdraw this offer
     * @param expirationDate Timestamp when the offer expires and can no longer be accepted
     * @param amount Amount offered in Principal Tokens (after 0.5% marketplace fee deduction)
     */
    struct OfferMetadata {
        address offerer;
        uint256 expirationDate;
        uint256 amount;
    }
}
