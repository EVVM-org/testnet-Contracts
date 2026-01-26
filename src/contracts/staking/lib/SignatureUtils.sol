// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;
/**
 * @title SignatureUtils
 * @author Mate Labs
 * @notice Library for EIP-191 signature verification in the Staking contract
 * @dev This library is exclusive to the Staking.sol contract and provides
 * functions to verify signatures for staking operations.
 *
 * Signature Format:
 * All signatures follow the EIP-191 standard with message format:
 * "[evvmID],[functionName],[isStaking],[amountOfStaking],[nonce]"
 *
 * Supported Operations:
 * - Presale staking: Limited staking for pre-approved addresses
 * - Public staking: Open staking for all users when enabled
 */

import {
    SignatureUtil
} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library SignatureUtils {
    /**
     * @dev Uses EIP-191 (https://eips.ethereum.org/EIPS/eip-191) for message signing
     *      and verification. The following functions verify messages signed by users
     *      for staking operations.
     */

    /**
     * @notice Verifies an EIP-191 signature for presale staking operations
     * @dev Message format: "[evvmID],presaleStaking,[isStaking],[amountOfStaking],[nonce]"
     *      Presale staking has a limit of 2 staking tokens per user
     * @param evvmID Unique identifier of the EVVM instance
     * @param signer Address that should have signed the message
     * @param isStaking True for staking operation, false for unstaking
     * @param amountOfStaking Amount of staking tokens (always 1 for presale)
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature 65-byte EIP-191 signature to verify
     * @return True if the signature is valid and matches the expected signer
     */
    function verifyMessageSignedForPresaleStake(
        uint256 evvmID,
        address signer,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "presaleStaking",
                string.concat(
                    AdvancedStrings.boolToString(isStaking),
                    ",",
                    AdvancedStrings.uintToString(amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies an EIP-191 signature for public staking operations
     * @dev Message format: "[evvmID],publicStaking,[isStaking],[amountOfStaking],[nonce]"
     *      Public staking is available to all users when the feature is enabled
     * @param evvmID Unique identifier of the EVVM instance
     * @param signer Address that should have signed the message
     * @param isStaking True for staking operation, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature 65-byte EIP-191 signature to verify
     * @return True if the signature is valid and matches the expected signer
     */
    function verifyMessageSignedForPublicStake(
        uint256 evvmID,
        address signer,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "publicStaking",
                string.concat(
                    AdvancedStrings.boolToString(isStaking),
                    ",",
                    AdvancedStrings.uintToString(amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }
}
