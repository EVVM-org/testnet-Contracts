// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    SignatureUtil
} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library NameServiceHashUtils {
    function hashDataForPreRegistrationUsername(
        bytes32 hashUsername
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("preRegistrationUsername", hashUsername));
    }

    function hashDataForRegistrationUsername(
        string memory username,
        uint256 lockNumber
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("registrationUsername", username, lockNumber));
    }

    function hashDataForMakeOffer(
        string memory username,
        uint256 amount,
        uint256 expirationDate
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("makeOffer", username, amount, expirationDate)
            );
    }

    function hashDataForWithdrawOffer(
        string memory username,
        uint256 offerId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("withdrawOffer", username, offerId));
    }

    function hashDataForAcceptOffer(
        string memory username,
        uint256 offerId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("acceptOffer", username, offerId));
    }

    function hashDataForRenewUsername(
        string memory username
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("renewUsername", username));
    }

    function hashDataForAddCustomMetadata(
        string memory identity,
        string memory value
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("addCustomMetadata", identity, value));
    }

    function hashDataForRemoveCustomMetadata(
        string memory identity,
        uint256 key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("removeCustomMetadata", identity, key));
    }

    function hashDataForFlushCustomMetadata(
        string memory identity
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("flushCustomMetadata", identity));
    }

    function hashDataForFlushUsername(
        string memory username
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("flushUsername", username));
    }
}
