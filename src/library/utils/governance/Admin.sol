// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 * @title Admin
 * @notice Base contract for admin-controlled contracts with time-delayed governance
 */
abstract contract Admin {
    ProposalStructs.AddressTypeProposal public admin;

    error SenderIsNotAdmin();
    error ProposalNotReady();

    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert SenderIsNotAdmin();
        _;
    }

    constructor(address initialAdmin) {
        admin.current = initialAdmin;
    }

    /**
     * @notice Proposes a new admin with time delay
     * @param newAdmin Address of proposed admin
     * @param delay Time delay before proposal can be accepted
     */
    function proposeAdmin(address newAdmin, uint256 delay) external onlyAdmin {
        admin.proposal = newAdmin;
        admin.timeToAccept = block.timestamp + delay;
    }

    function acceptAdminProposal() external onlyAdmin {
        if (block.timestamp < admin.timeToAccept) revert ProposalNotReady();
        admin.current = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }
}
