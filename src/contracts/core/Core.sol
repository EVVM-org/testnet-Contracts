// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    CoreStorage as Storage
} from "@evvm/testnet-contracts/contracts/core/lib/CoreStorage.sol";
import {
    CoreError as Error
} from "@evvm/testnet-contracts/library/errors/CoreError.sol";
import {
    CoreHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/CoreHashUtils.sol";
import {
    CoreStructs as Structs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    IUserValidator as UserValidator
} from "@evvm/testnet-contracts/interfaces/IUserValidator.sol";

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";

import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    SignatureRecover
} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";
import {CAUtils} from "@evvm/testnet-contracts/library/utils/CAUtils.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓██████▓▒░   
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        
 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░ 

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 * @title EVVM Core
 * @author Mate labs
 * @notice Central logic for EVVM payments, token management, and nonce tracking.
 * @dev Combines payment operations and nonce management.
 *      Features multi-token payments with EIP-191 signatures, dual nonce system (sync/async),
 *      and staker rewards. Governed by a time-delayed admin and implementation upgrade system.
 */

contract Core is Storage {
    /**
     * @notice Restricts access to the system administrator.
     */
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    /**
     * @notice Initializes the EVVM Core with basic system parameters.
     * @param _initialOwner Address granted administrative control.
     * @param _stakingContractAddress Address of the Staking contract.
     * @param _evvmMetadata Initial configuration (token info, reward amounts, etc.).
     */
    constructor(
        address _initialOwner,
        address _stakingContractAddress,
        Structs.EvvmMetadata memory _evvmMetadata
    ) {
        if (
            _initialOwner == address(0) || _stakingContractAddress == address(0)
        ) revert Error.AddressCantBeZero();

        evvmMetadata = _evvmMetadata;

        stakingContractAddress = _stakingContractAddress;

        admin.current = _initialOwner;

        balances[_stakingContractAddress][evvmMetadata.principalTokenAddress] =
            getRewardAmount() *
            2;

        stakerList[_stakingContractAddress] = FLAG_IS_STAKER;

        breakerSetupNameServiceAddress = FLAG_IS_STAKER;
    }

    /**
     * @notice Configures NameService and Treasury addresses once.
     * @dev Uses a breaker flag to prevent re-initialization.
     * @param _nameServiceAddress Address of the NameService contract.
     * @param _treasuryAddress Address of the Treasury contract.
     */
    function initializeSystemContracts(
        address _nameServiceAddress,
        address _treasuryAddress
    ) external {
        if (breakerSetupNameServiceAddress == 0x00)
            revert Error.BreakerExploded();

        if (_nameServiceAddress == address(0) || _treasuryAddress == address(0))
            revert Error.AddressCantBeZero();

        nameServiceAddress = _nameServiceAddress;
        balances[nameServiceAddress][evvmMetadata.principalTokenAddress] =
            10000 *
            10 ** 18;
        stakerList[nameServiceAddress] = FLAG_IS_STAKER;

        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Updates the EVVM ID within a 24-hour window after deployment or change.
     * @param newEvvmID New unique identifier for EIP-191 signatures.
     */
    function setEvvmID(uint256 newEvvmID) external onlyAdmin {
        if (evvmMetadata.EvvmID != 0) {
            if (block.timestamp > windowTimeToChangeEvvmID)
                revert Error.WindowExpired();
        }

        evvmMetadata.EvvmID = newEvvmID;

        windowTimeToChangeEvvmID = block.timestamp + 24 hours;
    }

    /**
     * @notice Proxy fallback forwarding calls to the active implementation.
     * @dev Uses delegatecall to execute logic within this contract's storage context.
     *      Reverts if currentImplementation is address(0).
     */
    fallback() external {
        if (currentImplementation == address(0))
            revert Error.ImplementationIsNotActive();

        assembly {
            /**
             *  Copy the data of the call
             *  copy s bytes of calldata from position
             *  f to mem in position t
             *  calldatacopy(t, f, s)
             */
            calldatacopy(0, 0, calldatasize())

            /**
             * 2. We make a delegatecall to the implementation
             *    and we copy the result
             */
            let result := delegatecall(
                gas(), // Send all the available gas
                sload(currentImplementation.slot), // Address of the implementation
                0, // Start of the memory where the data is
                calldatasize(), // Size of the data
                0, // Where we will store the response
                0 // Initial size of the response
            )

            /// Copy the response
            returndatacopy(0, 0, returndatasize())

            /// Handle the result
            switch result
            case 0 {
                revert(0, returndatasize()) // If it failed, revert
            }
            default {
                return(0, returndatasize()) // If it worked, return
            }
        }
    }

    /**
     * @notice Faucet: Adds balance to a user for testing (Testnet only).
     * @param user Recipient address.
     * @param token Token contract address.
     * @param quantity Amount to add.
     */
    function addBalance(
        address user,
        address token,
        uint256 quantity
    ) external {
        balances[user][token] += quantity;
    }

    /**
     * @notice Faucet: Sets staker status for testing (Testnet only).
     * @param user User address.
     * @param answer Status flag (e.g., FLAG_IS_STAKER).
     */
    function setPointStaker(address user, bytes1 answer) external {
        stakerList[user] = answer;
    }

    //░▒▓█ Payment Functions ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Processes a single token payment with signature verification.
     * @dev Validates nonce (sync/async), resolves identity (if provided), and updates balances.
     *      Rewarded if the executor is a staker.
     * @param from Sender address.
     * @param to_address Recipient address (overridden if to_identity is set).
     * @param to_identity Recipient username (resolved via NameService).
     * @param token Token address (address(0) for ETH).
     * @param amount Tokens to transfer.
     * @param priorityFee Fee paid to the executor (if staker).
     * @param senderExecutor Optional authorized executor (address(0) for any).
     * @param nonce Transaction nonce.
     * @param isAsyncExec True for parallel nonces, false for sequential.
     * @param signature EIP-191 authorization signature.
     */
    function pay(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external {
        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmMetadata.EvvmID,
                    address(this),
                    Hash.hashDataForPay(
                        to_address,
                        to_identity,
                        token,
                        amount,
                        priorityFee
                    ),
                    senderExecutor,
                    nonce,
                    isAsyncExec
                ),
                signature
            ) != from
        ) revert Error.InvalidSignature();

        if (!canExecuteUserTransaction(from))
            revert Error.UserCannotExecuteTransaction();

        if (isAsyncExec) {
            bytes1 statusNonce = asyncNonceStatus(from, nonce);
            if (asyncNonceStatus(from, nonce) == 0x01)
                revert Error.AsyncNonceAlreadyUsed();

            if (
                statusNonce == 0x02 &&
                asyncNonceReservedPointers[from][nonce] != address(this)
            ) revert Error.AsyncNonceIsReservedByAnotherService();

            asyncNonce[from][nonce] = true;
        } else {
            if (nonce != nextSyncNonce[from]) revert Error.SyncNonceMismatch();

            unchecked {
                ++nextSyncNonce[from];
            }
        }

        if ((senderExecutor != address(0)) && (msg.sender != senderExecutor))
            revert Error.SenderIsNotTheSenderExecutor();

        address to = !AdvancedStrings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        _updateBalance(from, to, token, amount);

        if (isAddressStaker(msg.sender)) {
            if (priorityFee > 0) {
                _updateBalance(from, msg.sender, token, priorityFee);
            }
            _giveReward(msg.sender, 1);
        }
    }

    /**
     * @notice Processes multiple payments in a single transaction.
     * @dev Each payment is validated and executed independently.
     * @param batchData Array of payment details and signatures.
     * @return successfulTransactions Count of successful payments.
     * @return results Success status for each payment in the batch.
     */
    function batchPay(
        Structs.BatchData[] memory batchData
    ) external returns (uint256 successfulTransactions, bool[] memory results) {
        bool isSenderStaker = isAddressStaker(msg.sender);
        address to_aux;
        Structs.BatchData memory payment;
        results = new bool[](batchData.length);

        for (uint256 iteration = 0; iteration < batchData.length; iteration++) {
            payment = batchData[iteration];

            if (
                SignatureRecover.recoverSigner(
                    AdvancedStrings.buildSignaturePayload(
                        evvmMetadata.EvvmID,
                        address(this),
                        Hash.hashDataForPay(
                            payment.to_address,
                            payment.to_identity,
                            payment.token,
                            payment.amount,
                            payment.priorityFee
                        ),
                        payment.senderExecutor,
                        payment.nonce,
                        payment.isAsyncExec
                    ),
                    payment.signature
                ) !=
                payment.from ||
                !canExecuteUserTransaction(payment.from)
            ) {
                results[iteration] = false;
                continue;
            }

            if (payment.isAsyncExec) {
                bytes1 statusNonce = asyncNonceStatus(
                    payment.from,
                    payment.nonce
                );
                if (
                    statusNonce == 0x01 ||
                    (statusNonce == 0x02 &&
                        asyncNonceReservedPointers[payment.from][
                            payment.nonce
                        ] !=
                        address(this))
                ) {
                    results[iteration] = false;
                    continue;
                }

                asyncNonce[payment.from][payment.nonce] = true;
            } else {
                if (payment.nonce != nextSyncNonce[payment.from]) {
                    results[iteration] = false;
                    continue;
                }

                unchecked {
                    ++nextSyncNonce[payment.from];
                }
            }

            if (
                (payment.senderExecutor != address(0) &&
                    msg.sender != payment.senderExecutor) ||
                ((isSenderStaker ? payment.priorityFee : 0) + payment.amount >
                    balances[payment.from][payment.token])
            ) {
                results[iteration] = false;
                continue;
            }

            if (!AdvancedStrings.equal(payment.to_identity, "")) {
                to_aux = NameService(nameServiceAddress).getOwnerOfIdentity(
                    payment.to_identity
                );
                if (to_aux == address(0)) {
                    results[iteration] = false;
                    continue;
                }
            } else {
                to_aux = payment.to_address;
            }

            /// @dev Because of the previous check, _updateBalance can´t fail

            _updateBalance(payment.from, to_aux, payment.token, payment.amount);

            if (payment.priorityFee > 0 && isSenderStaker)
                _updateBalance(
                    payment.from,
                    msg.sender,
                    payment.token,
                    payment.priorityFee
                );

            successfulTransactions++;
            results[iteration] = true;
        }

        if (isSenderStaker) _giveReward(msg.sender, successfulTransactions);
    }

    /**
     * @notice Distributes tokens from one sender to multiple recipients with a single signature.
     * @param from Sender address.
     * @param toData Array of recipient addresses/identities and their respective amounts.
     * @param token Token address.
     * @param amount Total amount to distribute (sum of toData).
     * @param priorityFee Fee for the executor (if staker).
     * @param nonce Transaction nonce.
     * @param isAsyncExec True for parallel nonces.
     * @param senderExecutor Optional authorized executor.
     * @param signature EIP-191 authorization signature.
     */
    function dispersePay(
        address from,
        Structs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external {
        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmMetadata.EvvmID,
                    address(this),
                    Hash.hashDataForDispersePay(
                        toData,
                        token,
                        amount,
                        priorityFee
                    ),
                    senderExecutor,
                    nonce,
                    isAsyncExec
                ),
                signature
            ) != from
        ) revert Error.InvalidSignature();

        if (!canExecuteUserTransaction(from))
            revert Error.UserCannotExecuteTransaction();

        if (isAsyncExec) {
            bytes1 statusNonce = asyncNonceStatus(from, nonce);
            if (asyncNonceStatus(from, nonce) == 0x01)
                revert Error.AsyncNonceAlreadyUsed();

            if (
                statusNonce == 0x02 &&
                asyncNonceReservedPointers[from][nonce] != address(this)
            ) revert Error.AsyncNonceIsReservedByAnotherService();

            asyncNonce[from][nonce] = true;
        } else {
            if (nonce != nextSyncNonce[from]) revert Error.SyncNonceMismatch();

            unchecked {
                ++nextSyncNonce[from];
            }
        }

        if ((senderExecutor != address(0)) && (msg.sender != senderExecutor))
            revert Error.SenderIsNotTheSenderExecutor();

        bool isSenderStaker = isAddressStaker(msg.sender);

        if (balances[from][token] < amount + (isSenderStaker ? priorityFee : 0))
            revert Error.InsufficientBalance();

        uint256 acomulatedAmount = 0;
        balances[from][token] -= (amount + (isSenderStaker ? priorityFee : 0));
        address to_aux;
        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;

            if (!AdvancedStrings.equal(toData[i].to_identity, "")) {
                if (
                    NameService(nameServiceAddress).strictVerifyIfIdentityExist(
                        toData[i].to_identity
                    )
                ) {
                    to_aux = NameService(nameServiceAddress).getOwnerOfIdentity(
                        toData[i].to_identity
                    );
                }
            } else {
                to_aux = toData[i].to_address;
            }

            balances[to_aux][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount) revert Error.InvalidAmount();

        if (isSenderStaker) {
            _giveReward(msg.sender, 1);
            balances[msg.sender][token] += priorityFee;
        }
    }

    /**
     * @notice Contract-to-address payment function for authorized
     *         smart contracts
     * @dev Allows registered contracts to distribute tokens without
     *      signature verification
     *
     * Authorization Model:
    /**
     * @notice Allows a smart contract (CA) to pay a recipient directly.
     * @dev No signature required as the contract itself is the caller.
     * @param to Recipient address.
     * @param token Token address.
     * @param amount Tokens to transfer.
     */
    function caPay(address to, address token, uint256 amount) external {
        address from = msg.sender;

        if (!CAUtils.verifyIfCA(from)) revert Error.NotAnCA();

        _updateBalance(from, to, token, amount);

        if (isAddressStaker(msg.sender)) _giveReward(msg.sender, 1);
    }

    /**
     * @notice Allows a smart contract (CA) to distribute tokens to multiple recipients.
     * @param toData Array of recipient addresses/identities and amounts.
     * @param token Token address.
     * @param amount Total amount to distribute.
     */
    function disperseCaPay(
        Structs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) external {
        address from = msg.sender;

        if (!CAUtils.verifyIfCA(from)) revert Error.NotAnCA();

        if (balances[from][token] < amount) revert Error.InsufficientBalance();

        uint256 acomulatedAmount = 0;

        balances[from][token] -= amount;

        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;
            balances[toData[i].toAddress][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount) revert Error.InvalidAmount();

        if (isAddressStaker(from)) _giveReward(from, 1);
    }

    //░▒▓█ Nonce and Signature Functions ██████████████████████████████████████████▓▒░

    /**
     * @notice Validates a user signature and consumes a nonce for an EVVM service.
     * @dev Only callable by smart contracts (EVVM services). Atomic verification/consumption.
     * @param user Address of the transaction signer.
     * @param hashPayload Hash of the transaction parameters.
     * @param originExecutor Optional tx.origin restriction (address(0) for none).
     * @param nonce Nonce to validate and consume.
     * @param isAsyncExec True for non-sequential nonces.
     * @param signature User's authorization signature.
     */
    function validateAndConsumeNonce(
        address user,
        bytes32 hashPayload,
        address originExecutor,
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
                    evvmMetadata.EvvmID,
                    servicePointer,
                    hashPayload,
                    originExecutor,
                    nonce,
                    isAsyncExec
                ),
                signature
            ) != user
        ) revert Error.InvalidSignature();

        if (originExecutor != address(0) && tx.origin != originExecutor)
            revert Error.OriginIsNotTheOriginExecutor();

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

    //░▒▓█ Nonce Reservation Functions ████████████████████████████████████████████▓▒░

    /**
     * @notice Reserves an async nonce for exclusive service use
     * @dev Allows users to pre-allocate nonces to specific services
     *
     * Reservation System:
     * - Users reserve nonces for specific service addresses
     * - Prevents other services from using reserved nonces
     * - Useful for multi-step or delayed operations
     * - Reservation persists until revoked or nonce is used
     *
     * Use Cases:
     * - Cross-chain operations requiring coordination
     * - Multi-signature workflows with specific executors
     * - Service-specific transaction queues
     * - Preventing front-running by other services
     *
     * Security Features:
     * - User-controlled reservation (msg.sender)
     * - Validates service address is not zero
     * - Prevents double reservation of same nonce
     * - Cannot reserve already-used nonces
     *
     * @param nonce The async nonce value to reserve
     * @param serviceAddress Service contract that can use nonce
     */
    function reserveAsyncNonce(uint256 nonce, address serviceAddress) external {
        if (serviceAddress == address(0)) revert Error.InvalidServiceAddress();

        if (asyncNonce[msg.sender][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[msg.sender][nonce] != address(0))
            revert Error.AsyncNonceAlreadyReserved();

        asyncNonceReservedPointers[msg.sender][nonce] = serviceAddress;
    }

    /**
     * @notice Revokes a previously reserved async nonce
     * @dev Allows clearing of nonce reservations for reuse
     *
     * Revocation Process:
     * - Validates nonce has not been used yet
     * - Checks that nonce is currently reserved
     * - Clears the service address reservation
     * - Nonce becomes available for any service
     *
     * Authorization:
     * - Currently callable by anyone (potential security issue)
     * - Should validate msg.sender is user or authorized
     * - Allows cancellation of mistaken reservations
     *
     * Use Cases:
     * - Canceling pending service operations
     * - Correcting accidental reservations
     * - Freeing nonces for different services
     * @param nonce The async nonce to revoke reservation for
     */
    function revokeAsyncNonce(uint256 nonce) external {
        if (asyncNonce[msg.sender][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[msg.sender][nonce] == address(0))
            revert Error.AsyncNonceNotReserved();

        asyncNonceReservedPointers[msg.sender][nonce] = address(0);
    }

    //░▒▓█ UserValidator Management Functions █████████████████████████████████████▓▒░

    /**
     * @notice Proposes new UserValidator contract address
     * @dev Initiates time-delayed governance for validator changes
     *
     * Governance Process:
     * - Admin proposes new validator contract address
     * - 1-day delay enforced before acceptance
     * - Allows community review of validator changes
     * - Can be canceled before acceptance
     *
     * UserValidator Integration:
     * - Optional contract for transaction filtering
     * - Called during validateAndConsumeNonce execution
     * - Can block specific users from executing transactions
     * - Useful for compliance or security requirements
     *
     * Security Features:
     * - Time-delayed governance (DELAY constant)
     * - Admin-only proposal capability
     * - Cancellation mechanism before activation
     *
     * @param newValidator Address of proposed UserValidator
     */
    function proposeUserValidator(address newValidator) external onlyAdmin {
        userValidatorAddress.proposal = newValidator;
        userValidatorAddress.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels pending UserValidator proposal
     * @dev Resets proposal state before time-lock expires
     *
     * @custom:access Admin only
     */
    function cancelUserValidatorProposal() external onlyAdmin {
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    /**
     * @notice Accepts UserValidator proposal after time-lock
     * @dev Activates new validator after delay period expires
     *
     * Activation Process:
     * - Validates time-lock period has passed
     * - Sets new validator as current active validator
     * - Clears proposal state
     * - Validator becomes active immediately
     *
     * Impact:
     * - All future transactions checked by new validator
     * - Affects validateAndConsumeNonce behavior
     * - Can block users from executing transactions
     *
     * @custom:access Admin only
     * @custom:timelock Requires DELAY (1 day) to have passed
     */
    function acceptUserValidatorProposal() external onlyAdmin {
        if (block.timestamp < userValidatorAddress.timeToAccept)
            revert Error.ProposalForUserValidatorNotReady();

        userValidatorAddress.current = userValidatorAddress.proposal;
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    //░▒▓█ Treasury Exclusive Functions ███████████████████████████████████████████▓▒░

    /**
     * @notice Adds tokens to a user's balance in the EVVM system
     * @dev Restricted function that can only be called by the authorized treasury contract
     *
     * Treasury Operations:
     * - Allows treasury to mint or credit tokens to user accounts
     * - Used for reward distributions, airdrops, or token bridging
     * - Direct balance manipulation bypasses normal transfer restrictions
     * - No signature verification required (treasury authorization)
     *
     * Access Control:
     * - Only the registered treasury contract can call this function
     * - Reverts with SenderIsNotTreasury error for unauthorized callers
     * - Provides centralized token distribution mechanism
     *
     * Use Cases:
     * - Cross-chain bridge token minting
     * - Administrative reward distributions
     * - System-level token allocations
     * - Emergency balance corrections
     *
     * @param user Address of the user to receive tokens
     * @param token Address of the token contract to add balance for
     * @param amount Amount of tokens to add to the user's balance
     *
     * @custom:access-control Only treasury contract
     * @custom:security No overflow protection needed due to controlled access
     */
    function addAmountToUser(
        address user,
        address token,
        uint256 amount
    ) external {
        if (msg.sender != treasuryAddress) revert Error.SenderIsNotTreasury();

        balances[user][token] += amount;
    }

    /**
     * @notice Deducts tokens from a user's system balance.
     * @dev Restricted to the authorized Treasury contract.
     * @param user Account to debit.
     * @param token Token address.
     * @param amount Amount to remove.
     */
    function removeAmountFromUser(
        address user,
        address token,
        uint256 amount
    ) external {
        if (msg.sender != treasuryAddress) revert Error.SenderIsNotTreasury();

        balances[user][token] -= amount;
    }

    //░▒▓█ Administrative Functions ████████████████████████████████████████████████████████▓▒░

    //██ Proxy Management █████████████████████████████████████████████

    /**
     * @notice Proposes a new implementation contract for the proxy (30-day delay).
     * @param _newImpl Address of the new logic contract.
     */
    function proposeImplementation(address _newImpl) external onlyAdmin {
        if (_newImpl == address(0)) revert Error.IncorrectAddressInput();
        proposalImplementation = _newImpl;
        timeToAcceptImplementation =
            block.timestamp +
            TIME_TO_ACCEPT_IMPLEMENTATION;
    }

    /**
     * @notice Cancels a pending implementation upgrade proposal.
     */
    function rejectUpgrade() external onlyAdmin {
        proposalImplementation = address(0);
        timeToAcceptImplementation = 0;
    }

    /**
     * @notice Finalizes the implementation upgrade after the time delay.
     */
    function acceptImplementation() external onlyAdmin {
        if (block.timestamp < timeToAcceptImplementation)
            revert Error.TimeLockNotExpired();

        currentImplementation = proposalImplementation;
        proposalImplementation = address(0);
        timeToAcceptImplementation = 0;
    }

    //██ Admin Management █████████████████████████████████████████████─

    /**
     * @notice Proposes a new administrator (1-day delay).
     * @param _newOwner Address of the proposed admin.
     */
    function proposeAdmin(address _newOwner) external onlyAdmin {
        if (_newOwner == address(0) || _newOwner == admin.current)
            revert Error.IncorrectAddressInput();

        admin = ProposalStructs.AddressTypeProposal({
            current: admin.current,
            proposal: _newOwner,
            timeToAccept: block.timestamp + TIME_TO_ACCEPT_PROPOSAL
        });
    }

    /**
     * @notice Cancels a pending admin change proposal.
     */
    function rejectProposalAdmin() external onlyAdmin {
        admin = ProposalStructs.AddressTypeProposal({
            current: admin.current,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    /**
     * @notice Finalizes the admin change after the time delay.
     * @dev Must be called by the proposed admin.
     */
    function acceptAdmin() external {
        if (block.timestamp < admin.timeToAccept)
            revert Error.TimeLockNotExpired();

        if (msg.sender != admin.proposal)
            revert Error.SenderIsNotTheProposedAdmin();

        admin = ProposalStructs.AddressTypeProposal({
            current: admin.proposal,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    //░▒▓█ Reward System Functions █████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Triggers a reward recalculation and era transition in the token economy
     * @dev Implements deflationary tokenomics with halving mechanism and random rewards
     *
     * Era Transition Mechanism:
     * - Activates when total supply exceeds current era token threshold
     * - Moves half of remaining tokens to next era threshold
     * - Halves the base reward amount for future transactions
     * - Provides random Principal Token bonus to caller (1-5083x reward)
     *
     * Economic Impact:
     * - Gradually reduces inflation through reward halving
     * - Creates scarcity as era thresholds become harder to reach
     * - Incentivizes early participation with higher rewards
     * - Provides lottery-style bonus for triggering era transitions
     *
     * Requirements:
     * - Total supply must exceed current era token threshold
     * - Can be called by anyone when conditions are met
     */
    function recalculateReward() public {
        if (evvmMetadata.totalSupply > evvmMetadata.eraTokens) {
            evvmMetadata.eraTokens += ((evvmMetadata.totalSupply -
                evvmMetadata.eraTokens) / 2);
            balances[msg.sender][evvmMetadata.principalTokenAddress] +=
                evvmMetadata.reward *
                getRandom(1, 5083);
            evvmMetadata.reward = evvmMetadata.reward / 2;
        } else {
            revert();
        }
    }

    /**
     * @notice Generates a pseudo-random number within a specified range
     * @dev Uses block timestamp and prevrandao for randomness (suitable for non-critical randomness)
     *
     * Randomness Source:
     * - Combines block.timestamp and block.prevrandao
     * - Suitable for reward bonuses and non-security-critical randomness
     * - Not suitable for high-stakes randomness requiring true unpredictability
     *
     * @param min Minimum value (inclusive)
     * @param max Maximum value (inclusive)
     * @return Random number between min and max (inclusive)
     */
    function getRandom(
        uint256 min,
        uint256 max
    ) internal view returns (uint256) {
        return
            min +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % (max - min + 1));
    }

    //░▒▓█ Staking Integration Functions █████████████████████████████████████████████████▓▒░

    /**
     * @notice Updates staker status for a user address
     * @dev Can only be called by the authorized staking contract
     *
     * Staker Status Management:
     * - Controls who can earn staking rewards and process transactions
     * - Integrates with external staking contract for validation
     * - Updates affect payment processing privileges and reward eligibility
     *
     * Access Control:
     * - Only the registered staking contract can call this function
     * - Ensures staker status changes are properly authorized
     *
     * @param user Address to update staker status for
     * @param answer Bytes1 flag indicating staker status/type
     */
    function pointStaker(address user, bytes1 answer) public {
        if (msg.sender != stakingContractAddress) revert();

        stakerList[user] = answer;
    }

    //░▒▓█ View Functions █████████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Returns the complete EVVM metadata configuration
     * @dev Provides access to system-wide configuration and economic parameters
     *
     * Metadata Contents:
     * - Principal token address (Principal Token)
     * - Current reward amount per transaction
     * - Total supply tracking
     * - Era tokens threshold for reward transitions
     * - System configuration parameters
     *
     * @return Complete EvvmMetadata struct with all system parameters
     */
    function getEvvmMetadata()
        external
        view
        returns (Structs.EvvmMetadata memory)
    {
        return evvmMetadata;
    }

    /**
     * @notice Gets the address representing the Principal Token in balance mappings
     * @dev Returns the virtual address used to track Principal Token balances in the balances mapping
     *      This is not an ERC20 contract address but a sentinel value for the EVVM-native token
     * @return Address used as the key for Principal Token balances
     */
    function getPrincipalTokenAddress() external view returns (address) {
        return evvmMetadata.principalTokenAddress;
    }

    /**
     * @notice Gets the address representing native chain currency (ETH/MATIC) in balance mappings
     * @dev Returns address(0) which is the standard sentinel for native blockchain tokens
     *      Use this address as the token parameter when dealing with ETH or chain-native assets
     * @return address(0) representing the native chain currency
     */
    function getChainHostCoinAddress() external pure returns (address) {
        return address(0);
    }

    /**
     * @notice Gets the unique identifier string for this EVVM instance
     * @dev Returns the EvvmID used for distinguishing different EVVM deployments
     * @return Unique EvvmID string
     */
    function getEvvmID() external view returns (uint256) {
        return evvmMetadata.EvvmID;
    }

    /**
     * @notice Gets the acceptance deadline for pending token whitelist proposals
     * @dev Returns timestamp when prepared tokens can be added to whitelist
     * @return Timestamp when pending token can be whitelisted (0 if no pending proposal)
     */
    function getWhitelistTokenToBeAddedDateToSet()
        external
        view
        returns (uint256)
    {
        return whitelistTokenToBeAdded_dateToSet;
    }

    /**
     * @notice Gets the current NameService contract address
     * @dev Returns the address used for identity resolution in payments
     * @return Address of the integrated NameService contract
     */
    function getNameServiceAddress() external view returns (address) {
        return nameServiceAddress;
    }

    /**
     * @notice Gets the authorized staking contract address
     * @dev Returns the address that can modify staker status and receive rewards
     * @return Address of the integrated staking contract
     */
    function getStakingContractAddress() external view returns (address) {
        return stakingContractAddress;
    }

    /**
     * @notice Gets the next Fisher Bridge deposit nonce for a user
     * @dev Returns the expected nonce for the next cross-chain deposit
     * @param user Address to check deposit nonce for
     * @return Next Fisher Bridge deposit nonce
     */
    function getNextFisherDepositNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherDepositNonce[user];
    }

    /**
     * @notice Gets the balance of a specific token for a user
     * @dev Returns the current balance stored in the EVVM system
     * @param user Address to check balance for
     * @param token Token contract address to check
     * @return Current token balance for the user
     */
    function getBalance(
        address user,
        address token
    ) external view returns (uint) {
        return balances[user][token];
    }

    /**
     * @notice Checks if an address is registered as a staker
     * @dev Verifies staker status for transaction processing privileges and rewards
     * @param user Address to check staker status for
     * @return True if the address is a registered staker
     */
    function isAddressStaker(address user) public view returns (bool) {
        return stakerList[user] == FLAG_IS_STAKER;
    }

    /**
     * @notice Gets the current era token threshold for reward transitions
     * @dev Returns the token supply threshold that triggers the next reward halving
     * @return Current era tokens threshold
     */
    function getEraPrincipalToken() public view returns (uint256) {
        return evvmMetadata.eraTokens;
    }

    /**
     * @notice Gets the current Principal Token reward amount per transaction
     * @dev Returns the base reward distributed to stakers for transaction processing
     * @return Current reward amount in Principal Tokens
     */
    function getRewardAmount() public view returns (uint256) {
        return evvmMetadata.reward;
    }

    /**
     * @notice Gets the total supply of the Principal Token
     * @dev Returns the current total supply used for era transition calculations
     * @return Total supply of Principal Tokens
     */
    function getPrincipalTokenTotalSupply() public view returns (uint256) {
        return evvmMetadata.totalSupply;
    }

    /**
     * @notice Gets the current active implementation contract address
     * @dev Returns the implementation used by the proxy for delegatecalls
     * @return Address of the current implementation contract
     */
    function getCurrentImplementation() public view returns (address) {
        return currentImplementation;
    }

    /**
     * @notice Gets the proposed implementation contract address
     * @dev Returns the implementation pending approval for proxy upgrade
     * @return Address of the proposed implementation contract (zero if none)
     */
    function getProposalImplementation() public view returns (address) {
        return proposalImplementation;
    }

    /**
     * @notice Gets the acceptance deadline for the pending implementation upgrade
     * @dev Returns timestamp when the proposed implementation can be accepted
     * @return Timestamp when implementation upgrade can be executed (0 if no pending proposal)
     */
    function getTimeToAcceptImplementation() public view returns (uint256) {
        return timeToAcceptImplementation;
    }

    /**
     * @notice Gets the current admin address
     * @dev Returns the address with administrative privileges over the contract
     * @return Address of the current admin
     */
    function getCurrentAdmin() public view returns (address) {
        return admin.current;
    }

    /**
     * @notice Gets the proposed admin address
     * @dev Returns the address pending approval for admin privileges
     * @return Address of the proposed admin (zero if no pending proposal)
     */
    function getProposalAdmin() public view returns (address) {
        return admin.proposal;
    }

    /**
     * @notice Gets the acceptance deadline for the pending admin change
     * @dev Returns timestamp when the proposed admin can accept the role
     * @return Timestamp when admin change can be executed (0 if no pending proposal)
     */
    function getTimeToAcceptAdmin() public view returns (uint256) {
        return admin.timeToAccept;
    }

    /**
     * @notice Gets the address of the token pending whitelist approval
     * @dev Returns the token address that can be whitelisted after time delay
     * @return Address of the token prepared for whitelisting (zero if none)
     */
    function getWhitelistTokenToBeAdded() public view returns (address) {
        return whitelistTokenToBeAdded_address;
    }

    /**
     * @notice Gets service address that reserved an async nonce
     * @dev Returns address(0) if nonce is not reserved
     *
     * @param user Address of the user who owns the nonce
     * @param nonce Async nonce to check reservation for
     * @return Service address that reserved the nonce, or
     *         address(0) if not reserved
     */
    function getAsyncNonceReservation(
        address user,
        uint256 nonce
    ) public view returns (address) {
        return asyncNonceReservedPointers[user][nonce];
    }

    /**
     * @notice Gets comprehensive status of an async nonce
     * @dev Returns byte code indicating nonce state
     *
     * Status Codes:
     * - 0x00: Available (can be used by any service)
     * - 0x01: Used (already consumed, cannot be reused)
     * - 0x02: Reserved (allocated to specific service)
     *
     * @param user Address of the user who owns the nonce
     * @param nonce Async nonce to check status for
     * @return Status code: 0x00 (available), 0x01 (used),
     *         or 0x02 (reserved)
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

    /**
     * @notice Gets current UserValidator contract address
     * @dev Returns address(0) if no validator is configured
     *
     * @return Address of active UserValidator contract
     */
    function getUserValidatorAddress() public view returns (address) {
        return userValidatorAddress.current;
    }

    /**
     * @notice Gets full UserValidator proposal details
     * @dev Returns current, proposed address and time-lock info
     *
     * @return Proposal struct with current validator address,
     *         proposed address, and time to accept
     */
    function getUserValidatorAddressDetails()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return userValidatorAddress;
    }

    //░▒▓█ Internal Functions █████████████████████████████████████████████████████▓▒░

    //██ Balance Management █████████████████████████████████████████████

    /**
     * @notice Internal function to safely transfer tokens between addresses
     * @dev Performs balance validation and atomic transfer with overflow protection
     *
     * Transfer Process:
     * - Validates sender has sufficient balance
     * - Performs atomic balance updates using unchecked arithmetic
     * - Returns success/failure status for error handling
     *
     * Security Features:
     * - Balance validation prevents overdrafts
     * - Unchecked arithmetic for gas optimization (overflow impossible)
     * - Returns boolean for caller error handling
     *
     * @param from Address to transfer tokens from
     * @param to Address to transfer tokens to
     * @param token Address of the token contract
     * @param value Amount of tokens to transfer
     */
    function _updateBalance(
        address from,
        address to,
        address token,
        uint256 value
    ) internal {
        uint256 fromBalance = balances[from][token];
        if (fromBalance < value) revert Error.InsufficientBalance();

        unchecked {
            balances[from][token] = fromBalance - value;
            balances[to][token] += value;
        }
    }

    /**
     * @notice Internal function to distribute Principal Token rewards to stakers
     * @dev Provides incentive distribution for transaction processing and staking participation
     *
     * Reward System:
     * - Calculates reward based on system reward rate and transaction count
     * - Directly increases principal token balance for gas efficiency
     * - Returns success status for error handling in calling functions
     *
     * Reward Calculation:
     * - Base reward per transaction: evvmMetadata.reward
     * - Total reward: base_reward × transaction_amount
     * - Added directly to user's Principal Token balance
     *
     * @param user Address of the staker to receive principal token rewards
     * @param amount Number of transactions or reward multiplier
     * @return success True if reward distribution completed successfully
     */
    function _giveReward(address user, uint256 amount) internal returns (bool) {
        uint256 principalReward = evvmMetadata.reward * amount;
        uint256 userBalance = balances[user][
            evvmMetadata.principalTokenAddress
        ];

        balances[user][evvmMetadata.principalTokenAddress] =
            userBalance +
            principalReward;

        return (userBalance + principalReward ==
            balances[user][evvmMetadata.principalTokenAddress]);
    }

    //██ User Validation █████████████████████████████████████████████

    /**
     * @notice Validates if user can execute transactions
     * @dev Checks with UserValidator if configured, allows all if not
     *
     * Validation Logic:
     * - If no validator configured: Returns true (all allowed)
     * - If validator configured: Delegates to validator.canExecute
     * - Used by validateAndConsumeNonce before nonce consumption
     *
     * Integration:
     * - Called during every transaction validation
     * - Allows external filtering of user transactions
     * - Supports compliance and security requirements
     *
     * @param user Address to check execution permission for
     * @return True if user can execute, false if blocked
     */
    function canExecuteUserTransaction(
        address user
    ) internal view returns (bool) {
        if (userValidatorAddress.current == address(0)) return true;
        return UserValidator(userValidatorAddress.current).canExecute(user);
    }
}
