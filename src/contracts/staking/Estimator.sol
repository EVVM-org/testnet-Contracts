// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
MM""""""""`M            dP   oo                       dP                     
MM  mmmmmmmM            88                            88                     
M`      MMMM .d8888b. d8888P dP 88d8b.d8b. .d8888b. d8888P .d8888b. 88d888b. 
MM  MMMMMMMM Y8ooooo.   88   88 88'`88'`88 88'  `88   88   88'  `88 88'  `88 
MM  MMMMMMMM       88   88   88 88  88  88 88.  .88   88   88.  .88 88       
MM        .M `88888P'   dP   dP dP  dP  dP `88888P8   dP   `88888P' dP       
MMMMMMMMMMMM                                                                 
                                                                            
 * @title Staking Estimator Contract
 * @author Mate labs
 */

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    StakingStructs
} from "@evvm/testnet-contracts/contracts/staking/lib/StakingStructs.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";

contract Estimator {
    struct AddressTypeProposal {
        address actual;
        address proposal;
        uint256 timeToAccept;
    }

    struct UintTypeProposal {
        uint256 actual;
        uint256 proposal;
        uint256 timeToAccept;
    }

    struct EpochMetadata {
        address tokenPool;
        uint256 totalPool;
        uint256 totalStaked;
        uint256 tFinal;
        uint256 tStart;
    }

    EpochMetadata private epoch;
    AddressTypeProposal private activator;
    AddressTypeProposal private evvmAddress;
    AddressTypeProposal private addressStaking;
    AddressTypeProposal private admin;

    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));
    bytes32 constant BEGUIN_IDENTIFIER = WITHDRAW_IDENTIFIER;

    bytes32 epochId = bytes32(uint256(3));

    modifier onlyStaking() {
        if (msg.sender != addressStaking.actual) revert();
        _;
    }

    modifier onlyActivator() {
        if (msg.sender != activator.actual) revert();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin.actual) revert();
        _;
    }

    constructor(
        address _activator,
        address _evvmAddress,
        address _addressStaking,
        address _admin
    ) {
        activator.actual = _activator;
        evvmAddress.actual = _evvmAddress;
        addressStaking.actual = _addressStaking;
        admin.actual = _admin;
    }

    function notifyNewEpoch(
        address tokenPool,
        uint256 totalPool,
        uint256 totalStaked,
        uint256 tStart
    ) public onlyActivator {
        epoch = EpochMetadata({
            tokenPool: tokenPool,
            totalPool: totalPool,
            totalStaked: totalStaked,
            tFinal: block.timestamp,
            tStart: tStart
        });
    }

    function makeEstimation(
        address _user
    )
        external
        onlyStaking
        returns (
            bytes32 epochAnswer,
            address tokenAddress,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwrite,
            uint256 timestampToOverwrite
        )
    {
        uint256 totSmLast;
        uint256 sumSmT;

        uint256 tLast = epoch.tStart;
        StakingStructs.HistoryMetadata memory h;
        uint256 size = Staking(addressStaking.actual).getSizeOfAddressHistory(
            _user
        );

        for (uint256 i = 0; i < size; i++) {
            h = Staking(addressStaking.actual).getAddressHistoryByIndex(
                _user,
                i
            );

            if (size == 1) totSmLast = h.totalStaked;

            if (h.timestamp > epoch.tFinal) {
                if (totSmLast > 0) sumSmT += (epoch.tFinal - tLast) * totSmLast;

                idToOverwrite = i;

                break;
            }

            if (h.transactionType == epochId) return (0, address(0), 0, 0, 0); // alv!!!!

            if (totSmLast > 0) sumSmT += (h.timestamp - tLast) * totSmLast;

            tLast = h.timestamp;
            totSmLast = h.totalStaked;
            idToOverwrite = i;
        }

        /**
         * @notice to get averageSm the formula is
         *              __ n
         *              \
         *              /       [(ti -ti-1) * Si-1] x 10**18
         *              --i=1
         * averageSm = --------------------------------------
         *                       tFinal - tStart
         *
         * where
         *          ti   ----- timestamp of current iteration
         *          ti-1 ----- timestamp of previus iteration
         *          t final -- epoch end
         *          t zero  -- start of epoch
         */

        uint256 averageSm = (sumSmT * 1e18) / (epoch.tFinal - epoch.tStart);

        amountTotalToBeRewarded =
            (averageSm * (epoch.totalPool / epoch.totalStaked)) /
            1e18;

        timestampToOverwrite = epoch.tFinal;

        epoch.totalPool -= amountTotalToBeRewarded;
        epoch.totalStaked -= h.totalStaked;
    }

    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻
    // Admin functions
    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻

    function setActivatorProposal(address _proposal) external onlyActivator {
        activator.proposal = _proposal;
        activator.timeToAccept = block.timestamp + 1 days;
    }

    function cancelActivatorProposal() external onlyActivator {
        activator.proposal = address(0);
        activator.timeToAccept = 0;
    }

    function acceptActivatorProposal() external {
        if (block.timestamp < activator.timeToAccept) revert();

        activator.actual = activator.proposal;
        activator.proposal = address(0);
        activator.timeToAccept = 0;
    }

    function setEvvmAddressProposal(address _proposal) external onlyAdmin {
        evvmAddress.proposal = _proposal;
        evvmAddress.timeToAccept = block.timestamp + 1 days;
    }

    function cancelEvvmAddressProposal() external onlyAdmin {
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

    function acceptEvvmAddressProposal() external onlyAdmin {
        if (block.timestamp < evvmAddress.timeToAccept) revert();

        evvmAddress.actual = evvmAddress.proposal;
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

    function setAddressStakingProposal(address _proposal) external onlyAdmin {
        addressStaking.proposal = _proposal;
        addressStaking.timeToAccept = block.timestamp + 1 days;
    }

    function cancelAddressStakingProposal() external onlyAdmin {
        addressStaking.proposal = address(0);
        addressStaking.timeToAccept = 0;
    }

    function acceptAddressStakingProposal() external onlyAdmin {
        if (block.timestamp < addressStaking.timeToAccept) revert();

        addressStaking.actual = addressStaking.proposal;
        addressStaking.proposal = address(0);
        addressStaking.timeToAccept = 0;
    }

    function setAdminProposal(address _proposal) external onlyAdmin {
        admin.proposal = _proposal;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    function cancelAdminProposal() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    function acceptAdminProposal() external {
        if (block.timestamp < admin.timeToAccept) revert();

        admin.actual = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻
    // Getters
    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻

    function getEpochMetadata() external view returns (EpochMetadata memory) {
        return epoch;
    }

    function getActualEpochInUint() external view returns (uint256) {
        return uint256(epochId) - 2;
    }

    function getActualEpochInFormat() external view returns (bytes32) {
        return epochId;
    }

    function getActivatorMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return activator;
    }

    function getEvvmAddressMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return evvmAddress;
    }

    function getAddressStakingMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return addressStaking;
    }

    function getAdminMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return admin;
    }

    function simulteEstimation(
        address _user
    )
        external
        view
        returns (
            bytes32 epochAnswer,
            address tokenAddress,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwrite,
            uint256 timestampToOverwrite
        )
    {
        uint256 totSmLast;
        uint256 sumSmT;

        uint256 tLast = epoch.tStart;
        StakingStructs.HistoryMetadata memory h;
        uint256 size = Staking(addressStaking.actual).getSizeOfAddressHistory(
            _user
        );

        for (uint256 i = 0; i < size; i++) {
            h = Staking(addressStaking.actual).getAddressHistoryByIndex(
                _user,
                i
            );

            if (h.timestamp > epoch.tFinal) {
                if (size == 1) totSmLast = h.totalStaked;

                if (totSmLast > 0) sumSmT += (epoch.tFinal - tLast) * totSmLast;

                idToOverwrite = i;

                break;
            }

            if (h.transactionType == epochId) return (0, address(0), 0, 0, 0); // alv!!!!

            if (totSmLast > 0) sumSmT += (h.timestamp - tLast) * totSmLast;

            tLast = h.timestamp;
            totSmLast = h.totalStaked;
            idToOverwrite = i;
        }

        uint256 averageSm = (sumSmT * 1e18) / (epoch.tFinal - epoch.tStart);

        amountTotalToBeRewarded =
            (averageSm * (epoch.totalPool / epoch.totalStaked)) /
            1e18;

        timestampToOverwrite = epoch.tFinal;
    }
}
