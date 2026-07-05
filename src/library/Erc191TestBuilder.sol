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
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    CoreHashUtils
} from "@evvm/testnet-contracts/library/utils/signature/CoreHashUtils.sol";
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
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    CoreHashUtils.hashDataForPay(
                        to_address,
                        to_identity,
                        token,
                        amount,
                        priorityFee
                    ),
                    originExecutor,
                    nonce,
                    isAsyncExec
                )
            );
    }

    function buildMessageSignedForDispersePay(
        uint256 evvmID,
        CoreStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec
    ) public pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    CoreHashUtils.hashDataForDispersePay(
                        toData,
                        token,
                        amount,
                        priorityFee
                    ),
                    originExecutor,
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
        bytes32 hashPreRegisteredUsername,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForPreRegistrationUsername(
                        hashPreRegisteredUsername
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRegistrationUsername(
        uint256 evvmID,
        string memory username,
        uint256 lockNumber,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForRegistrationUsername(
                        username,
                        lockNumber
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForMakeOffer(
        uint256 evvmID,
        string memory username,
        uint256 amount,
        uint256 expirationDate,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForMakeOffer(
                        username,
                        amount,
                        expirationDate
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForWithdrawOffer(
        uint256 evvmID,
        string memory username,
        uint256 offerId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForWithdrawOffer(
                        username,
                        offerId
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForAcceptOffer(
        uint256 evvmID,
        string memory username,
        uint256 offerId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForAcceptOffer(
                        username,
                        offerId
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRenewUsername(
        uint256 evvmID,
        string memory username,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForRenewUsername(username),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        string memory username,
        string memory value,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForAddCustomMetadata(
                        username,
                        value
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        string memory username,
        uint256 key,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForRemoveCustomMetadata(
                        username,
                        key
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        string memory username,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForFlushCustomMetadata(
                        username
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForFlushUsername(
        uint256 evvmID,
        string memory username,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    NameServiceHashUtils.hashDataForFlushUsername(username),
                    originExecutor,
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
        bool isStaking,
        uint256 amountOfStaking,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    StakingHashUtils.hashDataForPresaleStake(
                        isStaking,
                        amountOfStaking
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForPublicStaking(
        uint256 evvmID,
        bool isStaking,
        uint256 amountOfStaking,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    StakingHashUtils.hashDataForPublicStake(
                        isStaking,
                        amountOfStaking
                    ),
                    originExecutor,
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
        address offeredToken,
        address requestedToken,
        uint256 offeredAmount,
        uint256 requestedAmount,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    P2PSwapHashUtils.hashDataForMakeOrder(
                        offeredToken,
                        requestedToken,
                        offeredAmount,
                        requestedAmount
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForCancelOrder(
        uint256 evvmID,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    P2PSwapHashUtils.hashDataForCancelOrder(
                        offeredToken,
                        requestedToken,
                        orderId
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    function buildMessageSignedForDispatchOrder(
        uint256 evvmID,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax,
        address senderExecutor,
        address originExecutor,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    P2PSwapHashUtils.hashDataForDispatchOrder(
                        offeredToken,
                        requestedToken,
                        orderId,
                        amountOut,
                        amountInMax
                    ),
                    originExecutor,
                    nonce,
                    true
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // nonceConsumer functions
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForStateTest(
        uint256 evvmID,
        string memory testA,
        uint256 testB,
        address testC,
        bool testD,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec
    ) internal pure returns (bytes32) {
        return
            buildHashForSign(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    senderExecutor,
                    keccak256(
                        abi.encode("StateTest", testA, testB, testC, testD)
                    ),
                    originExecutor,
                    nonce,
                    isAsyncExec
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
