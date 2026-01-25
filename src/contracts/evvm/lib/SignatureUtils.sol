// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    SignatureUtil
} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library SignatureUtils {
    /**
     *  @dev using EIP-191 (https://eips.ethereum.org/EIPS/eip-191) can be used to sign and
     *       verify messages, the next functions are used to verify the messages signed
     *       by the users
     */

    /**
     *  @notice This function is used to verify the message signed for the payment
     *  @param signer user who signed the message
     *  @param receiverAddress address of the receiver
     *  @param receiverIdentity identity of the receiver
     *
     *  @notice if the receiverAddress is 0x0 the function will use the receiverIdentity
     *
     *  @param token address of the token to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the staking holder
     *  @param nonce nonce of the transaction
     *  @param priorityFlag if the transaction is priority or not
     *  @param executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
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
     *  @notice This function is used to verify the message signed for the dispersePay
     *  @param signer user who signed the message
     *  @param hashList hash of the list of the transactions, the hash is calculated
     *                  using sha256(abi.encode(toData))
     *  @param token token address to send
     *  @param amount amount to send
     *  @param priorityFee priorityFee to send to the fisher who wants to send the message
     *  @param nonce nonce of the transaction
     *  @param priorityFlag if the transaction is priority or not
     *  @param executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
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
