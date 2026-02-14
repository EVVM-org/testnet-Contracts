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
                                                                            
 * @title EVVM Staking Estimator
 * @author Mate Labs
 * @notice Calculates validator rewards using time-weighted averages.
 * @dev Collaborates with Staking.sol to track epochs, total staked amounts, and distribution pools. 
 *      Features time-delayed governance for administrative changes.
 */
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    StakingStructs
} from "@evvm/testnet-contracts/library/structs/StakingStructs.sol";


contract Estimator {
    /// @dev Struct for managing address change proposals with time delay
    struct AddressTypeProposal {
        address actual;
        address proposal;
        uint256 timeToAccept;
    }

    /// @dev Struct for managing uint256 value proposals with time delay
    struct UintTypeProposal {
        uint256 actual;
        uint256 proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct containing epoch metadata for reward calculations
     * @param tokenPool Address of the token being distributed as rewards
     * @param totalPool Total amount of tokens available for distribution
     * @param totalStaked Total staking tokens staked during this epoch
     * @param tFinal Timestamp when the epoch ended
     * @param tStart Timestamp when the epoch started
     */
    struct EpochMetadata {
        address tokenPool;
        uint256 totalPool;
        uint256 totalStaked;
        uint256 tFinal;
        uint256 tStart;
    }

    /// @dev Current epoch metadata storage
    EpochMetadata private epoch;
    /// @dev Proposal system for activator address changes
    AddressTypeProposal private activator;
    /// @dev Proposal system for EVVM address changes
    AddressTypeProposal private coreAddress;
    /// @dev Proposal system for Staking contract address changes
    AddressTypeProposal private addressStaking;
    /// @dev Proposal system for admin address changes
    AddressTypeProposal private admin;

    /// @dev Transaction type identifier for deposit (staking) operations
    bytes32 constant DEPOSIT_IDENTIFIER = bytes32(uint256(1));
    /// @dev Transaction type identifier for withdraw (unstaking) operations
    bytes32 constant WITHDRAW_IDENTIFIER = bytes32(uint256(2));
    /// @dev Beginning identifier same as withdraw for epoch tracking
    bytes32 constant BEGUIN_IDENTIFIER = WITHDRAW_IDENTIFIER;

    /// @dev Current epoch identifier, increments with each new epoch
    bytes32 epochId = bytes32(uint256(3));

    /// @dev Restricts function access to the Staking contract only
    modifier onlyStaking() {
        if (msg.sender != addressStaking.actual) revert();
        _;
    }

    /// @dev Restricts function access to the activator address only
    modifier onlyActivator() {
        if (msg.sender != activator.actual) revert();
        _;
    }

    /// @dev Restricts function access to the admin address only
    modifier onlyAdmin() {
        if (msg.sender != admin.actual) revert();
        _;
    }

    /**
     * @notice Initializes the Estimator contract
     * @dev Sets up all required addresses for contract operation
     * @param _activator Address authorized to start new epochs
     * @param _coreAddress Address of the EVVM core contract
     * @param _addressStaking Address of the Staking contract
     * @param _admin Address with administrative privileges
     */
    constructor(
        address _activator,
        address _coreAddress,
        address _addressStaking,
        address _admin
    ) {
        activator.actual = _activator;
        coreAddress.actual = _coreAddress;
        addressStaking.actual = _addressStaking;
        admin.actual = _admin;
    }

    /**
     * @notice Starts a new reward epoch with the provided parameters
     * @dev Only callable by the activator address. Records epoch metadata for reward calculations.
     * @param tokenPool Address of the token to be distributed as rewards
     * @param totalPool Total amount of tokens available for distribution this epoch
     * @param totalStaked Total staking tokens staked at epoch start
     * @param tStart Timestamp when the epoch started
     */
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

    /**
     * @notice Calculates and returns the reward amount for a specific user
     * @dev Only callable by the Staking contract. Uses time-weighted average calculation
     *      to determine proportional rewards based on staking duration and amount.
     * @param _user Address of the user to calculate rewards for
     * @return epochAnswer Epoch identifier to record in user history
     * @return tokenAddress Address of the reward token
     * @return amountTotalToBeRewarded Calculated reward amount for the user
     * @return idToOverwrite Index in user history to update with reward info
     * @return timestampToOverwrite Timestamp to record for the reward transaction
     */
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

    /// @notice Proposes a new activator address with 1-day time delay
    /// @param _proposal Address of the proposed new activator
    function setActivatorProposal(address _proposal) external onlyActivator {
        activator.proposal = _proposal;
        activator.timeToAccept = block.timestamp + 1 days;
    }

    /// @notice Cancels the pending activator proposal
    function cancelActivatorProposal() external onlyActivator {
        activator.proposal = address(0);
        activator.timeToAccept = 0;
    }

    /// @notice Accepts the activator proposal after time delay
    function acceptActivatorProposal() external {
        if (block.timestamp < activator.timeToAccept) revert();

        activator.actual = activator.proposal;
        activator.proposal = address(0);
        activator.timeToAccept = 0;
    }

    /// @notice Proposes a new EVVM address with 1-day time delay
    /// @param _proposal Address of the proposed new EVVM contract
    function setEvvmAddressProposal(address _proposal) external onlyAdmin {
        coreAddress.proposal = _proposal;
        coreAddress.timeToAccept = block.timestamp + 1 days;
    }

    /// @notice Cancels the pending EVVM address proposal
    function cancelEvvmAddressProposal() external onlyAdmin {
        coreAddress.proposal = address(0);
        coreAddress.timeToAccept = 0;
    }

    /// @notice Accepts the EVVM address proposal after time delay
    function acceptEvvmAddressProposal() external onlyAdmin {
        if (block.timestamp < coreAddress.timeToAccept) revert();

        coreAddress.actual = coreAddress.proposal;
        coreAddress.proposal = address(0);
        coreAddress.timeToAccept = 0;
    }

    /// @notice Proposes a new Staking contract address with 1-day time delay
    /// @param _proposal Address of the proposed new Staking contract
    function setAddressStakingProposal(address _proposal) external onlyAdmin {
        addressStaking.proposal = _proposal;
        addressStaking.timeToAccept = block.timestamp + 1 days;
    }

    /// @notice Cancels the pending Staking address proposal
    function cancelAddressStakingProposal() external onlyAdmin {
        addressStaking.proposal = address(0);
        addressStaking.timeToAccept = 0;
    }

    /// @notice Accepts the Staking address proposal after time delay
    function acceptAddressStakingProposal() external onlyAdmin {
        if (block.timestamp < addressStaking.timeToAccept) revert();

        addressStaking.actual = addressStaking.proposal;
        addressStaking.proposal = address(0);
        addressStaking.timeToAccept = 0;
    }

    /// @notice Proposes a new admin address with 1-day time delay
    /// @param _proposal Address of the proposed new admin
    function setAdminProposal(address _proposal) external onlyAdmin {
        admin.proposal = _proposal;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    /// @notice Cancels the pending admin proposal
    function cancelAdminProposal() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /// @notice Accepts the admin proposal after time delay
    function acceptAdminProposal() external {
        if (block.timestamp < admin.timeToAccept) revert();

        admin.actual = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻
    // Getters
    //⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎽⎼⎻⎺⎺⎻⎼⎽⎼⎻⎺⎺⎻

    /// @notice Returns the current epoch metadata
    /// @return Complete EpochMetadata struct with pool and timing information
    function getEpochMetadata() external view returns (EpochMetadata memory) {
        return epoch;
    }

    /// @notice Returns the current epoch number as uint256
    /// @return Current epoch number (epochId - 2)
    function getActualEpochInUint() external view returns (uint256) {
        return uint256(epochId) - 2;
    }

    /// @notice Returns the current epoch identifier in bytes32 format
    /// @return Current epoch identifier
    function getActualEpochInFormat() external view returns (bytes32) {
        return epochId;
    }

    /// @notice Returns the activator address proposal information
    /// @return Complete AddressTypeProposal struct for activator
    function getActivatorMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return activator;
    }

    /// @notice Returns the EVVM address proposal information
    /// @return Complete AddressTypeProposal struct for EVVM
    function getCoreAddressMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return coreAddress;
    }

    /// @notice Returns the Staking contract address proposal information
    /// @return Complete AddressTypeProposal struct for Staking
    function getAddressStakingMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return addressStaking;
    }

    /// @notice Returns the admin address proposal information
    /// @return Complete AddressTypeProposal struct for admin
    function getAdminMetadata()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return admin;
    }

    /**
     * @notice Simulates reward estimation without modifying state
     * @dev View function for previewing rewards before claiming
     * @param _user Address of the user to simulate rewards for
     * @return epochAnswer Epoch identifier that would be recorded
     * @return tokenAddress Address of the reward token
     * @return amountTotalToBeRewarded Calculated reward amount
     * @return idToOverwrite Index in user history that would be updated
     * @return timestampToOverwrite Timestamp that would be recorded
     */
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
