// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 * @title Admin Governance Base Contract
 * @author Mate labs
 * @notice Time-delayed admin governance with propose/accept pattern
 * @dev Abstract base using ProposalStructs.AddressTypeProposal. Recommended delay: 1 day (86400s).
 */
abstract contract Admin {
    /**
     * @notice Admin proposal with time-delayed acceptance
     * @dev Stores current, proposed, and acceptance time
     */
    ProposalStructs.AddressTypeProposal public admin;

    /// @dev Thrown when caller is not current admin
    error SenderIsNotAdmin();
    /// @dev Thrown when proposal acceptance attempted early
    error ProposalNotReady();

    /**
     * @notice Restricts function access to current admin
     */
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert SenderIsNotAdmin();
        _;
    }

    /**
     * @notice Initializes admin governance with initial admin address
     * @dev Sets admin.current without time delay. Only called during construction.
     * @param initialAdmin Address of first admin
     */
    constructor(address initialAdmin) {
        admin.current = initialAdmin;
    }

    /**
     * @notice Proposes new admin with custom time delay
     * @dev Sets admin.proposal and admin.timeToAccept (block.timestamp + delay). Only current admin.
     * @param newAdmin Proposed new admin address
     * @param delay Seconds before acceptance allowed
     */
    function proposeAdmin(address newAdmin, uint256 delay) external onlyAdmin {
        admin.proposal = newAdmin;
        admin.timeToAccept = block.timestamp + delay;
    }

    /**
     * @notice Accepts admin proposal after time delay
     * @dev Transfers admin role to proposed address. Reverts if block.timestamp < timeToAccept. Only current admin.
     */
    function acceptAdminProposal() external onlyAdmin {
        if (block.timestamp < admin.timeToAccept) revert ProposalNotReady();
        admin.current = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }
}
