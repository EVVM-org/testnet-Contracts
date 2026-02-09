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

    /**
     * @notice Builds the message hash for public service staking
     * @dev Creates an EIP-191 compatible hash for Staking publicServiceStaking
     * @param evvmID Unique identifier of the EVVM instance
     * @param _serviceAddress Address of the service to stake for
     * @param _isStaking True for staking, false for unstaking
     * @param _amountOfStaking Amount of staking units
     * @param _nonce Nonce for replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForPublicServiceStake(
        uint256 evvmID,
        address _serviceAddress,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "publicServiceStaking",
                    ",",
                    AdvancedStrings.addressToString(_serviceAddress),
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for public staking
     * @dev Creates an EIP-191 compatible hash for Staking publicStaking
     * @param evvmID Unique identifier of the EVVM instance
     * @param _isStaking True for staking, false for unstaking
     * @param _amountOfStaking Amount of staking units
     * @param _nonce Nonce for replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForPublicStaking(
        uint256 evvmID,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "publicStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for presale staking
     * @dev Creates an EIP-191 compatible hash for Staking presaleStaking
     * @param evvmID Unique identifier of the EVVM instance
     * @param _isStaking True for staking, false for unstaking
     * @param _amountOfStaking Amount of staking units
     * @param _nonce Nonce for replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForPresaleStaking(
        uint256 evvmID,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "presaleStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // P2PSwap functions
    //-----------------------------------------------------------------------------------

    /**
     * @notice Builds the message hash for making a P2P swap order
     * @dev Creates an EIP-191 compatible hash for P2PSwap makeOrder
     * @param evvmID Unique identifier of the EVVM instance
     * @param _nonce Nonce for replay protection
     * @param _tokenA Token address being offered
     * @param _tokenB Token address being requested
     * @param _amountA Amount of tokenA being offered
     * @param _amountB Amount of tokenB being requested
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForMakeOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "makeOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_amountA),
                    ",",
                    AdvancedStrings.uintToString(_amountB)
                )
            );
    }

    /**
     * @notice Builds the message hash for canceling a P2P swap order
     * @dev Creates an EIP-191 compatible hash for P2PSwap cancelOrder
     * @param evvmID Unique identifier of the EVVM instance
     * @param _nonce Nonce for replay protection
     * @param _tokenA Token address that was offered
     * @param _tokenB Token address that was requested
     * @param _orderId ID of the order to cancel
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForCancelOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "cancelOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
                )
            );
    }

    /**
     * @notice Builds the message hash for dispatching (accepting) a P2P swap order
     * @dev Creates an EIP-191 compatible hash for P2PSwap dispatchOrder
     * @param evvmID Unique identifier of the EVVM instance
     * @param _nonce Nonce for replay protection
     * @param _tokenA Token address that was offered
     * @param _tokenB Token address that was requested
     * @param _orderId ID of the order to dispatch
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForDispatchOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "dispatchOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
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
