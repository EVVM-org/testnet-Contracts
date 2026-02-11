// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library StakingHashUtils {
    function hashDataForPresaleStake(
        bool isStaking,
        uint256 amountOfStaking
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("presaleStaking", isStaking, amountOfStaking));
    }

    function hashDataForPublicStake(
        bool isStaking,
        uint256 amountOfStaking
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("publicStaking", isStaking, amountOfStaking));
    }
}
