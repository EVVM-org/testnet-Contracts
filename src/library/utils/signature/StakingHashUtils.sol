// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

/**
 * @title Staking Hash Utilities
 * @author Mate labs
 * @notice Hash functions for staking signature validation (presale/public)
 * @dev Generates unique hashes with operation-specific prefixes. Used with State.sol async nonces. Cost: 5083 PT per token.
 */
library StakingHashUtils {
    /**
     * @notice Hashes presale staking operation parameters for signature validation
     * @dev Hash: keccak256("presaleStaking", isStaking, amountOfStaking). Used with State.sol async nonces. Max 2 tokens per user.
     * @param isStaking true=stake, false=unstake
     * @param amountOfStaking Number of staking tokens
     * @return Hash for signature validation
     */
    function hashDataForPresaleStake(
        bool isStaking,
        uint256 amountOfStaking
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("presaleStaking", isStaking, amountOfStaking));
    }

    /**
     * @notice Hashes public staking operation parameters for signature validation
     * @dev Hash: keccak256("publicStaking", isStaking, amountOfStaking). Used with State.sol async nonces. Unlimited tokens per user.
     * @param isStaking true=stake, false=unstake
     * @param amountOfStaking Number of staking tokens
     * @return Hash for signature validation
     */
    function hashDataForPublicStake(
        bool isStaking,
        uint256 amountOfStaking
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("publicStaking", isStaking, amountOfStaking));
    }
}
