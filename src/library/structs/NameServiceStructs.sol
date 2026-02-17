// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title NameServiceStructs
 * @author Mate labs
 * @notice Data structures for NameService.sol (identity, marketplace, governance)
 * @dev Identity and marketplace structures. Nonce validation and payment processing via Core.sol.
 */
library NameServiceStructs {

    //░▒▓█ Identity Management Structures ███████████████████████████████████████████████▓▒░

    /**
     * @notice Core metadata for registered identity/username
     * @dev Registration states: flagNotAUsername (0x01=pre-reg, 0x00=active). Renewable up to 100 years. Cost: 100x EVVM reward.
     * @param owner Owner address
     * @param expirationDate Registration expiry timestamp
     * @param customMetadataMaxSlots Metadata entry count
     * @param offerMaxSlots Highest offer ID
     * @param flagNotAUsername Registration state flag
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
     * @dev Lifecycle: Created (locked PT with 0.5% fee) → Active (can be accepted/withdrawn) → Completed (offerer = address(0)).
     * @param offerer Offer creator (can withdraw)
     * @param expirationDate Offer expiry timestamp
     * @param amount PT offered (after 0.5% fee)
     */
    struct OfferMetadata {
        address offerer;
        uint256 expirationDate;
        uint256 amount;
    }
}
