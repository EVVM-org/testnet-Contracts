// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title Proposal Data Structures
 * @author Mate labs
 * @notice Time-delayed governance proposal structures for safe parameter changes
 * @dev Three proposal types: AddressTypeProposal, UintTypeProposal, BoolTypeProposal. Standard delay: 1 day (86400s).
 */
library ProposalStructs {
    /**
     * @notice Time-delayed address change proposal
     * @dev Used for admin, executor, and contract address updates
     * @param current Currently active address
     * @param proposal Proposed new address
     * @param timeToAccept Timestamp when proposal becomes acceptable
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @notice Time-delayed numeric value proposal
     * @dev Used for fees, limits, rates, and thresholds
     * @param current Currently active value
     * @param proposal Proposed new value
     * @param timeToAccept Timestamp when proposal becomes acceptable
     */
    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }

    /**
     * @notice Time-delayed boolean flag proposal
     * @dev Used for pause/unpause, enable/disable features. Not suitable for instant emergency stops.
     * @param flag Current boolean state
     * @param timeToAccept Timestamp when toggle allowed
     */
    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAccept;
    }
}
