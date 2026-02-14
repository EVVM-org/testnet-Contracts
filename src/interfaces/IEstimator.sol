// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

interface IEstimator {
    struct AddressTypeProposal {
        address actual;
        address proposal;
        uint256 timeToAccept;
    }

    struct EpochMetadata {
        address tokenPool;
        uint256 totalPool;
        uint256 totalStaked;
        uint256 tFinal;
        uint256 tStart;
    }

    function acceptActivatorProposal() external;
    function acceptAddressStakingProposal() external;
    function acceptAdminProposal() external;
    function acceptEvvmAddressProposal() external;
    function cancelActivatorProposal() external;
    function cancelAddressStakingProposal() external;
    function cancelAdminProposal() external;
    function cancelEvvmAddressProposal() external;
    function getActivatorMetadata() external view returns (AddressTypeProposal memory);
    function getActualEpochInFormat() external view returns (bytes32);
    function getActualEpochInUint() external view returns (uint256);
    function getAddressStakingMetadata() external view returns (AddressTypeProposal memory);
    function getAdminMetadata() external view returns (AddressTypeProposal memory);
    function getCoreAddressMetadata() external view returns (AddressTypeProposal memory);
    function getEpochMetadata() external view returns (EpochMetadata memory);
    function makeEstimation(address _user)
        external
        returns (
            bytes32 epochAnswer,
            address tokenAddress,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwrite,
            uint256 timestampToOverwrite
        );
    function notifyNewEpoch(address tokenPool, uint256 totalPool, uint256 totalStaked, uint256 tStart) external;
    function setActivatorProposal(address _proposal) external;
    function setAddressStakingProposal(address _proposal) external;
    function setAdminProposal(address _proposal) external;
    function setEvvmAddressProposal(address _proposal) external;
    function simulteEstimation(address _user)
        external
        view
        returns (
            bytes32 epochAnswer,
            address tokenAddress,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwrite,
            uint256 timestampToOverwrite
        );
}
