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
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {EvvmHashUtils} from "@evvm/testnet-contracts/library/utils/signature/EvvmHashUtils.sol";

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
        return buildHashForSign(
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
        return buildHashForSign(
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

    /**
     * @notice Builds the message hash for username pre-registration
     * @dev Creates an EIP-191 compatible hash for NameService preRegistrationUsername
     * @param evvmID Unique identifier of the EVVM instance
     * @param _hashUsername Hash of username + random number for commit-reveal
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForPreRegistrationUsername(
        uint256 evvmID,
        bytes32 _hashUsername,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "preRegistrationUsername",
                    ",",
                    AdvancedStrings.bytes32ToString(_hashUsername),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for username registration
     * @dev Creates an EIP-191 compatible hash for NameService registrationUsername
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username The username being registered
     * @param _lockNumber Random number from pre-registration
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForRegistrationUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _lockNumber,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "registrationUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_lockNumber),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for making a username offer
     * @dev Creates an EIP-191 compatible hash for NameService makeOffer
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Target username for the offer
     * @param _dateExpire Timestamp when the offer expires
     * @param _amount Amount being offered in Principal Tokens
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForMakeOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _dateExpire,
        uint256 _amount,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "makeOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_dateExpire),
                    ",",
                    AdvancedStrings.uintToString(_amount),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for withdrawing a username offer
     * @dev Creates an EIP-191 compatible hash for NameService withdrawOffer
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username the offer was made for
     * @param _offerId ID of the offer to withdraw
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForWithdrawOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "withdrawOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_offerId),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for accepting a username offer
     * @dev Creates an EIP-191 compatible hash for NameService acceptOffer
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username being sold
     * @param _offerId ID of the offer to accept
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForAcceptOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "acceptOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_offerId),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for renewing a username
     * @dev Creates an EIP-191 compatible hash for NameService renewUsername
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username to renew
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForRenewUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "renewUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for adding custom metadata
     * @dev Creates an EIP-191 compatible hash for NameService addCustomMetadata
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username to add metadata to
     * @param _value Metadata value following schema format
     * @param _nameServiceNonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        string memory _username,
        string memory _value,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "addCustomMetadata",
                    ",",
                    _username,
                    ",",
                    _value,
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for removing custom metadata
     * @dev Creates an EIP-191 compatible hash for NameService removeCustomMetadata
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username to remove metadata from
     * @param _key Index of the metadata entry to remove
     * @param _nonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        string memory _username,
        uint256 _key,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "removeCustomMetadata",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_key),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for flushing all custom metadata
     * @dev Creates an EIP-191 compatible hash for NameService flushCustomMetadata
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username to flush metadata from
     * @param _nonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "flushCustomMetadata",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    /**
     * @notice Builds the message hash for flushing a username
     * @dev Creates an EIP-191 compatible hash for NameService flushUsername
     * @param evvmID Unique identifier of the EVVM instance
     * @param _username Username to completely remove
     * @param _nonce Nonce for NameService replay protection
     * @return messageHash The EIP-191 formatted hash ready for signing
     */
    function buildMessageSignedForFlushUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "flushUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
