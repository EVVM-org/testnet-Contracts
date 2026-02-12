// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/*
  █████████ █████           █████           
 ███▒▒▒▒▒██▒▒███           ▒▒███            
▒███    ▒▒▒███████  ██████ ███████   ██████ 
▒▒████████▒▒▒███▒  ▒▒▒▒▒██▒▒▒███▒   ███▒▒███
 ▒▒▒▒▒▒▒▒███▒███    ███████ ▒███   ▒███████ 
 ███    ▒███▒███ █████▒▒███ ▒███ ██▒███▒▒▒  
▒▒█████████ ▒▒████▒▒████████▒▒█████▒▒██████ 
 ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒                                                                                            
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    SignatureRecover
} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    StateError as Error
} from "@evvm/testnet-contracts/library/errors/StateError.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
import {
    IUserValidator
} from "@evvm/testnet-contracts/interfaces/IUserValidator.sol";
import {
    Admin
} from "@evvm/testnet-contracts/library/utils/governance/Admin.sol";
import {
    CAUtils
} from "@evvm/testnet-contracts/library/utils/CAUtils.sol";

contract State is Admin {
    uint256 private constant DELAY = 1 days;

    Evvm private evvm;

    ProposalStructs.AddressTypeProposal public userValidatorAddress;

    /**
     * @notice Flexible nonce tracking for asynchronous transactions
     * @dev Nonces can be used in any order but only once
     *      Provides flexibility for parallel transaction submission
     *      Marked as used (true) after consumption
     */
    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncNonce;

    mapping(address user => mapping(uint256 nonce => address serviceReserved))
        private asyncNonceReservedPointers;

    /**
     * @notice Sequential nonce tracking for synchronous transactions
     * @dev Nonces must be used in strict sequential order (0, 1, 2, ...)
     *      Provides ordered transaction execution and simpler replay protection
     *      Incremented after each successful sync transaction
     */
    mapping(address user => uint256 nonce) private nextSyncNonce;

    constructor(address evvmAddress, address initialAdmin) Admin(initialAdmin) {
        evvm = Evvm(evvmAddress);
    }

    function validateAndConsumeNonce(
        address user,
        bytes32 hashPayload,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external {
        address servicePointer = msg.sender;

        if (!CAUtils.verifyIfCA(servicePointer))
            revert Error.MsgSenderIsNotAContract();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvm.getEvvmID(),
                    servicePointer,
                    hashPayload,
                    nonce,
                    isAsyncExec
                ),
                signature
            ) != user
        ) revert Error.InvalidSignature();

        if (!canExecuteUserTransaction(user))
            revert Error.UserCannotExecuteTransaction();

        if (isAsyncExec) {
            bytes1 statusNonce = asyncNonceStatus(user, nonce);
            if (asyncNonceStatus(user, nonce) == 0x01)
                revert Error.AsyncNonceAlreadyUsed();

            if (
                statusNonce == 0x02 &&
                asyncNonceReservedPointers[user][nonce] != servicePointer
            ) revert Error.AsyncNonceIsReservedByAnotherService();

            asyncNonce[user][nonce] = true;
        } else {
            if (nonce != nextSyncNonce[user]) revert Error.SyncNonceMismatch();

            unchecked {
                ++nextSyncNonce[user];
            }
        }
    }

    function reserveAsyncNonce(
        address user,
        uint256 nonce,
        address serviceAddress
    ) external {
        if (asyncNonce[user][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[user][nonce] != address(0))
            revert Error.AsyncNonceAlreadyReserved();

        asyncNonceReservedPointers[user][nonce] = serviceAddress;
    }

    function revokeAsyncNonce(address user, uint256 nonce) external {
        if (asyncNonce[user][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[user][nonce] == address(0))
            revert Error.AsyncNonceNotReserved();

        asyncNonceReservedPointers[user][nonce] = address(0);
    }

    /**
     * @notice Checks if a specific nonce has been used by a user
     * @dev Public view function for external queries and UI integration
     * @param user Address of the user to check
     * @param nonce The nonce value to query
     * @return True if the nonce has been used, false if available
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncNonce[user][nonce];
    }

    /**
     * @notice Gets the current (next expected) nonce for a user
     * @dev Public view function for external queries and transaction preparation
     * @param user Address of the user to query
     * @return The next nonce value that must be used by the user
     */
    function getNextCurrentSyncNonce(
        address user
    ) public view virtual returns (uint256) {
        return nextSyncNonce[user];
    }

    function getEvvmID() public view returns (uint256) {
        return evvm.getEvvmID();
    }

    function getEvvmAddress() public view returns (address) {
        return address(evvm);
    }

    function getAsyncNonceReservation(
        address user,
        uint256 nonce
    ) public view returns (address) {
        return asyncNonceReservedPointers[user][nonce];
    }

    function isAsyncNonceReserved(
        address user,
        uint256 nonce
    ) public view returns (bool) {
        return asyncNonceReservedPointers[user][nonce] != address(0);
    }

    /*returns bnyte1
            0x00 = available
            0x01 = used
            0x02 = reserved
         */
    function asyncNonceStatus(
        address user,
        uint256 nonce
    ) public view returns (bytes1) {
        if (asyncNonce[user][nonce]) {
            return 0x01;
        } else if (asyncNonceReservedPointers[user][nonce] != address(0)) {
            return 0x02;
        } else {
            return 0x00;
        }
    }

    function proposeUserValidator(address newValidator) external onlyAdmin {
        userValidatorAddress.proposal = newValidator;
        userValidatorAddress.timeToAccept = block.timestamp + DELAY;
    }

    function cancelUserValidatorProposal() external onlyAdmin {
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    function acceptUserValidatorProposal() external onlyAdmin {
        if (block.timestamp < userValidatorAddress.timeToAccept)
            revert Error.ProposalForUserValidatorNotReady();

        userValidatorAddress.current = userValidatorAddress.proposal;
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    function canExecuteUserTransaction(
        address user
    ) internal view returns (bool) {
        if (userValidatorAddress.current == address(0)) return true;
        return IUserValidator(userValidatorAddress.current).canExecute(user);
    }
}
