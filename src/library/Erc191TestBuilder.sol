// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title Erc191TestBuilder
 * @author jistro.eth
 * @notice this library is used to build ERC191 messages for foundry test scripts
 *         more info in
 *         https://book.getfoundry.sh/cheatcodes/create-wallet
 *         https://book.getfoundry.sh/cheatcodes/sign
 */

import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    EvvmHashUtils
} from "@evvm/testnet-contracts/library/utils/signature/EvvmHashUtils.sol";
import {
    NameServiceHashUtils
} from "@evvm/testnet-contracts/library/utils/signature/NameServiceHashUtils.sol";
import {
    P2PSwapHashUtils
} from "@evvm/testnet-contracts/library/utils/signature/P2PSwapHashUtils.sol";
import {
    StakingHashUtils
} from "@evvm/testnet-contracts/library/utils/signature/StakingHashUtils.sol";

library Erc191TestBuilder {
    //-----------------------------------------------------------------------------------
    // EVVM
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForPay(
        uint256 evvmID,
        address servicePointer,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    EvvmHashUtils.hashDataForPay(
                        to_address,
                        to_identity,
                        token,
                        amount,
                        priorityFee,
                        executor
                    ),
                    nonce,
                    isAsyncExec
                )
            );
    }

    function buildMessageSignedForDispersePay(
        uint256 evvmID,
        address servicePointer,
        EvvmStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec
    ) public pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    EvvmHashUtils.hashDataForDispersePay(
                        toData,
                        token,
                        amount,
                        priorityFee,
                        executor
                    ),
                    nonce,
                    isAsyncExec
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // MATE NAME SERVICE
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForPreRegistrationUsername(
        uint256 evvmID,
        address servicePointer,
        bytes32 hashPreRegisteredUsername,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForPreRegistrationUsername(
                        hashPreRegisteredUsername
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRegistrationUsername(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 lockNumber,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForRegistrationUsername(
                        username,
                        lockNumber
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForMakeOffer(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 amount,
        uint256 expirationDate,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForMakeOffer(
                        username,
                        amount,
                        expirationDate
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForWithdrawOffer(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 offerId,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForWithdrawOffer(
                        username,
                        offerId
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForAcceptOffer(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 offerId,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForAcceptOffer(
                        username,
                        offerId
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRenewUsername(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForRenewUsername(username),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        string memory value,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForAddCustomMetadata(
                        username,
                        value
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 key,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForRemoveCustomMetadata(
                        username,
                        key
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForFlushCustomMetadata(
                        username
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForFlushUsername(
        uint256 evvmID,
        address servicePointer,
        string memory username,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    NameServiceHashUtils.hashDataForFlushUsername(username),
                    nonce,
                    true
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // staking functions
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForPresaleStaking(
        uint256 evvmID,
        address servicePointer,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    StakingHashUtils.hashDataForPresaleStake(
                        isStaking,
                        amountOfStaking
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForPublicStaking(
        uint256 evvmID,
        address servicePointer,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    StakingHashUtils.hashDataForPublicStake(
                        isStaking,
                        amountOfStaking
                    ),
                    nonce,
                    true
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // P2PSwap functions
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForMakeOrder(
        uint256 evvmID,
        address servicePointer,
        uint256 nonce,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    P2PSwapHashUtils.hashDataForMakeOrder(
                        tokenA,
                        tokenB,
                        amountA,
                        amountB
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForCancelOrder(
        uint256 evvmID,
        address servicePointer,
        uint256 nonce,
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    P2PSwapHashUtils.hashDataForCancelOrder(
                        tokenA,
                        tokenB,
                        orderId
                    ),
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForDispatchOrder(
        uint256 evvmID,
        address servicePointer,
        uint256 nonce,
        address tokenA,
        address tokenB,
        uint256 orderId
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    servicePointer,
                    P2PSwapHashUtils.hashDataForDispatchOrder(
                        tokenA,
                        tokenB,
                        orderId
                    ),
                    nonce,
                    true
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // General functions
    //-----------------------------------------------------------------------------------

    /**
     * @notice Creates an EIP-191 formatted hash from a message string
     * @dev Prepends the Ethereum Signed Message prefix and message length
     * @param messageToSign The message string to hash
     * @return The EIP-191 formatted hash ready for signature verification
     */
    function buildHashForSign(
        string memory messageToSign
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    AdvancedStrings.uintToString(bytes(messageToSign).length),
                    messageToSign
                )
            );
    }

    /**
     * @notice Combines signature components into a 65-byte signature
     * @dev Packs r, s, and v into the standard EIP-191 signature format
     * @param v Recovery identifier (27 or 28)
     * @param r First 32 bytes of the signature
     * @param s Second 32 bytes of the signature
     * @return 65-byte encoded signature in (r, s, v) format
     */
    function buildERC191Signature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, bytes1(v));
    }
}
