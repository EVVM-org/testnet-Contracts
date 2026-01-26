// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title SignatureUtil
 * @author Mate Labs
 * @notice Library for EIP-191 signature verification in EVVM services
 * @dev Provides a standardized method for verifying signatures in EVVM-compatible services.
 * The signature message format follows a consistent pattern:
 * "[evvmID],[functionName],[inputs]"
 *
 * This library is designed for use by community-developed services to implement
 * signature verification that is compatible with the EVVM ecosystem standard.
 *
 * Example Usage:
 * ```solidity
 * bool isValid = SignatureUtil.verifySignature(
 *     evvmID,
 *     "myFunction",
 *     "param1,param2,param3",
 *     signature,
 *     expectedSigner
 * );
 * ```
 */

import {SignatureRecover} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library SignatureUtil {
    /**
     * @notice Verifies an EIP-191 signature for a service function call
     * @dev Constructs the expected message from the provided parameters and verifies
     *      the signature was created by the expected signer. The message format is:
     *      "[evvmID],[functionName],[inputs]"
     * @param evvmID Unique identifier of the EVVM instance (for chain-specific signatures)
     * @param functionName Name of the function being called
     * @param inputs Comma-separated string of function input values
     * @param signature 65-byte EIP-191 signature to verify
     * @param expectedSigner Address that should have signed the message
     * @return True if the signature is valid and matches the expected signer
     */
    function verifySignature(
        uint256 evvmID,
        string memory functionName,
        string memory inputs,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        return
            SignatureRecover.recoverSigner(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    functionName,
                    ",",
                    inputs
                ),
                signature
            ) == expectedSigner;
    }
}
