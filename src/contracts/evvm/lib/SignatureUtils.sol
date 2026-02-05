// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    SignatureUtil
} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

/**
 * @title SignatureUtils
 * @author Mate labs
 * @notice Library for EIP-191 signature verification exclusively for Evvm.sol payment functions
 * @dev This library provides signature verification utilities for the Evvm.sol contract,
 *      specifically for payment operations (pay and dispersePay). It constructs the message
 *      format expected by users and validates their signatures.
 *
 * Signature Verification:
 * - Uses EIP-191 standard for message signing and verification
 * - Constructs deterministic message strings from payment parameters
 * - Integrates with SignatureUtil for cryptographic verification
 * - Prevents replay attacks through nonce inclusion
 * - Supports cross-chain safety through EvvmID inclusion
 *
 * Message Format:
 * - pay: "receiver,token,amount,priorityFee,nonce,priorityFlag,executor"
 * - dispersePay: "hashOfRecipients,token,amount,priorityFee,nonce,priorityFlag,executor"
 *
 * @custom:scope Exclusive to Evvm.sol payment functions
 * @custom:standard EIP-191 (https://eips.ethereum.org/EIPS/eip-191)
 * @custom:security All signatures include EvvmID to prevent cross-chain replay attacks
 */
library SignatureUtils {

    /**
     * @notice Verifies EIP-191 signature for single payment operations
     * @dev Constructs the expected message from payment parameters and verifies
     *      the signature matches the signer. Used in pay() and batchPay() functions.
     *
     * Message Construction:
     * - If receiverAddress is address(0): uses receiverIdentity string
     * - Otherwise: converts receiverAddress to string
     * - Concatenates all parameters with comma separators
     * - Includes EvvmID for cross-chain replay protection
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (payment sender)
     * @param receiverAddress Direct recipient address (used if receiverIdentity is empty)
     * @param receiverIdentity Username/identity to resolve (takes priority over address)
     * @param token Address of the token to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Fee paid to the staker/fisher processing the transaction
     * @param nonce Transaction nonce for replay protection
     * @param priorityFlag False for sync nonce (sequential), true for async nonce (flexible)
     * @param executor Address authorized to execute this transaction (address(0) = anyone)
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForPay(
        uint256 evvmID,
        address signer,
        address receiverAddress,
        string memory receiverIdentity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "pay",
                string.concat(
                    receiverAddress == address(0)
                        ? receiverIdentity
                        : AdvancedStrings.addressToString(receiverAddress),
                    ",",
                    AdvancedStrings.addressToString(token),
                    ",",
                    AdvancedStrings.uintToString(amount),
                    ",",
                    AdvancedStrings.uintToString(priorityFee),
                    ",",
                    AdvancedStrings.uintToString(nonce),
                    ",",
                    AdvancedStrings.boolToString(priorityFlag),
                    ",",
                    AdvancedStrings.addressToString(executor)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for multi-recipient disperse payment operations
     * @dev Constructs the expected message from disperse parameters and verifies
     *      the signature matches the signer. Used in dispersePay() function.
     *
     * Message Construction:
     * - Uses sha256 hash of recipient array instead of full data (gas optimization)
     * - Concatenates hash and all other parameters with comma separators
     * - Includes EvvmID for cross-chain replay protection
     *
     * Hash Calculation:
     * - Client must calculate: sha256(abi.encode(toData))
     * - toData is DispersePayMetadata[] array with recipients and amounts
     * - Ensures tamper-proof verification of all recipients
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (payment sender)
     * @param hashList SHA256 hash of the recipient data array: sha256(abi.encode(toData))
     * @param token Address of the token to distribute
     * @param amount Total amount being distributed (must equal sum of individual amounts)
     * @param priorityFee Fee paid to the staker/fisher processing the distribution
     * @param nonce Transaction nonce for replay protection
     * @param priorityFlag False for sync nonce (sequential), true for async nonce (flexible)
     * @param executor Address authorized to execute this distribution (address(0) = anyone)
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForDispersePay(
        uint256 evvmID,
        address signer,
        bytes32 hashList,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "dispersePay",
                string.concat(
                    AdvancedStrings.bytes32ToString(hashList),
                    ",",
                    AdvancedStrings.addressToString(token),
                    ",",
                    AdvancedStrings.uintToString(amount),
                    ",",
                    AdvancedStrings.uintToString(priorityFee),
                    ",",
                    AdvancedStrings.uintToString(nonce),
                    ",",
                    AdvancedStrings.boolToString(priorityFlag),
                    ",",
                    AdvancedStrings.addressToString(executor)
                ),
                signature,
                signer
            );
    }
}
