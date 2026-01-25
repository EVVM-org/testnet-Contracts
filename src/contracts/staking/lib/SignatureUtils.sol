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
