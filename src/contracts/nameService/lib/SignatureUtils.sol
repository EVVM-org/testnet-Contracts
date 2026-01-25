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

    function verifyMessageSignedForPreRegistrationUsername(
        uint256 evvmID,
        address signer,
        bytes32 hashUsername,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "preRegistrationUsername",
                string.concat(
                    AdvancedStrings.bytes32ToString(hashUsername),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRegistrationUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 clowNumber,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "registrationUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(clowNumber),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForMakeOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 dateExpire,
        uint256 amount,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "makeOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(dateExpire),
                    ",",
                    AdvancedStrings.uintToString(amount),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForWithdrawOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 offerId,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "withdrawOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(offerId),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForAcceptOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 offerId,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "acceptOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(offerId),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRenewUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "renewUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory identity,
        string memory value,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "addCustomMetadata",
                string.concat(
                    identity,
                    ",",
                    value,
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 key,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "removeCustomMetadata",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(key),
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory identity,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "flushCustomMetadata",
                string.concat(
                    identity,
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForFlushUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "flushUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }
}
