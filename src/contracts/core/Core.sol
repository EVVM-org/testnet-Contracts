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

        rewardFlowDistribution.flag = true;

        _giveReward(_stakingContractAddress, 2);

        stakerList[_stakingContractAddress] = FLAG_IS_STAKER;

        breakerSetupNameServiceAddress = true;
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
        if (!breakerSetupNameServiceAddress) revert Error.BreakerExploded();

        if (_nameServiceAddress == address(0) || _treasuryAddress == address(0))
            revert Error.AddressCantBeZero();

        nameServiceAddress = _nameServiceAddress;

        _giveReward(_nameServiceAddress, 20);

        stakerList[nameServiceAddress] = FLAG_IS_STAKER;

        treasuryAddress = _treasuryAddress;

        breakerSetupNameServiceAddress = false;
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

    //░▒▓█ Testnet Functions ██████████████████████████████████████████████████████▓▒░

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

        if (token == evvmMetadata.principalTokenAddress)
            currentSupply += quantity;
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
        string calldata to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes calldata signature
    ) external {
        validateAndConsumeNonce(
            from,
            senderExecutor,
            Hash.hashDataForPay(
                to_address,
                to_identity,
                token,
                amount,
                priorityFee
            ),
            originExecutor,
            nonce,
            isAsyncExec,
            signature
        );

        address to = !AdvancedStrings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        _updateBalance(from, to, token, amount);

        if (isAddressStaker(msg.sender)) {
            if (priorityFee > 0)
                _updateBalance(from, msg.sender, token, priorityFee);

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
        Structs.BatchData[] calldata batchData
    ) external returns (uint256 successfulTransactions, bool[] memory results) {
        bool isSenderStaker = isAddressStaker(msg.sender);
        address to_aux;
        Structs.BatchData calldata payment;
        results = new bool[](batchData.length);

        for (uint256 iteration = 0; iteration < batchData.length; iteration++) {
            payment = batchData[iteration];

            try
                this.validateAndConsumeNonce(
                    payment.from,
                    payment.senderExecutor,
                    Hash.hashDataForPay(
                        payment.to_address,
                        payment.to_identity,
                        payment.token,
                        payment.amount,
                        payment.priorityFee
                    ),
                    payment.originExecutor,
                    payment.nonce,
                    payment.isAsyncExec,
                    payment.signature
                )
            {} catch {
                results[iteration] = false;
                continue;
            }
            if (
                (listStatus.current == 0x01 && !allowList[payment.token]) ||
                (listStatus.current == 0x02 && denyList[payment.token])
            ) {
                results[iteration] = false;
                continue;
            }

            if (
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
        Structs.DispersePayMetadata[] calldata toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes calldata signature
    ) external {
        validateAndConsumeNonce(
            from,
            senderExecutor,
            Hash.hashDataForDispersePay(toData, token, amount, priorityFee),
            originExecutor,
            nonce,
            isAsyncExec,
            signature
        );

        bool isSenderStaker = isAddressStaker(msg.sender);

        if (balances[from][token] < amount + (isSenderStaker ? priorityFee : 0))
            revert Error.InsufficientBalance();

        if (listStatus.current != 0x00) _verifyTokenInteractionAllowance(token);

        uint256 acomulatedAmount = 0;
        balances[from][token] -= (amount + (isSenderStaker ? priorityFee : 0));
        address to_aux;
        for (uint256 i = 0; i < toData.length; ) {
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

            unchecked {
                i++;
            }
        }

        if (acomulatedAmount != amount) revert Error.InvalidAmount();

        if (isSenderStaker) {
            _giveReward(msg.sender, 1);
            balances[msg.sender][token] += priorityFee;
        }
    }

    /**
     * @notice Allows a smart contract (CA) to pay a recipient directly.
     * @dev No signature required; the contract itself is the caller.
     * @param to Recipient address.
     * @param token Token address.
     * @param amount Tokens to transfer.
     */
    function caPay(address to, address token, uint256 amount) external {
        address from = msg.sender;

        if (!canExecuteUserTransaction(from))
            revert Error.UserCannotExecuteTransaction();

        _updateBalance(msg.sender, to, token, amount);

        if (isAddressStaker(msg.sender)) _giveReward(msg.sender, 1);
    }

    /**
     * @notice Allows a smart contract (CA) to distribute tokens to multiple recipients.
     * @param toData Array of recipient addresses/identities and amounts.
     * @param token Token address.
     * @param amount Total amount to distribute.
     */
    function disperseCaPay(
        Structs.DisperseCaPayMetadata[] calldata toData,
        address token,
        uint256 amount
    ) external {
        if (listStatus.current != 0x00) _verifyTokenInteractionAllowance(token);

        address from = msg.sender;

        if (!CAUtils.verifyIfCA(from)) revert Error.NotAnCA();

        if (balances[from][token] < amount) revert Error.InsufficientBalance();

        uint256 acomulatedAmount = 0;

        balances[from][token] -= amount;

        for (uint256 i = 0; i < toData.length; ) {
            acomulatedAmount += toData[i].amount;
            balances[toData[i].toAddress][token] += toData[i].amount;

            unchecked {
                i++;
            }
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
        address senderExecutor,
        bytes32 hashPayload,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes calldata signature
    ) public {
        address senderPointer = msg.sender;
        address originPointer = tx.origin;

        if (senderExecutor != address(0) && senderPointer != senderExecutor)
            revert Error.SenderMismatch();

        if (originExecutor != address(0) && originPointer != originExecutor)
            revert Error.OriginMismatch();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmMetadata.EvvmID,
                    senderExecutor,
                    hashPayload,
                    originExecutor,
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
                (asyncNonceReservedPointers[user][nonce] != senderPointer ||
                    asyncNonceReservedPointers[user][nonce] != originPointer)
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
     * @notice Reserves an async nonce for exclusive use by a specific service.
     * @param nonce Nonce to reserve.
     * @param senderExecutor Service contract authorized to consume the nonce.
     */
    function reserveAsyncNonce(uint256 nonce, address senderExecutor) external {
        if (senderExecutor == address(0)) revert Error.InvalidServiceAddress();

        if (asyncNonce[msg.sender][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[msg.sender][nonce] != address(0))
            revert Error.AsyncNonceAlreadyReserved();

        asyncNonceReservedPointers[msg.sender][nonce] = senderExecutor;
    }

    /**
     * @notice Clears a previously reserved async nonce, making it available again.
     * @param nonce Nonce to unreserve.
     */
    function revokeAsyncNonce(uint256 nonce) external {
        if (asyncNonce[msg.sender][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[msg.sender][nonce] == address(0))
            revert Error.AsyncNonceNotReserved();

        asyncNonceReservedPointers[msg.sender][nonce] = address(0);
    }

    //░▒▓█ UserValidator Management Functions █████████████████████████████████████▓▒░

    /**
     * @notice Proposes a new UserValidator contract (1-day delay).
     * @param newValidator Address of the proposed UserValidator contract.
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
     * @notice Finalizes the UserValidator proposal after the time-lock.
     */
    function acceptUserValidatorProposal() external onlyAdmin {
        if (block.timestamp < userValidatorAddress.timeToAccept)
            revert Error.ProposalNotReadyToAccept();

        userValidatorAddress.current = userValidatorAddress.proposal;
        userValidatorAddress.proposal = address(0);
        userValidatorAddress.timeToAccept = 0;
    }

    //░▒▓█ Treasury Exclusive Functions ███████████████████████████████████████████▓▒░

    /**
     * @notice Credits tokens to a user's balance. Restricted to the Treasury contract.
     * @param user Recipient address.
     * @param token Token address.
     * @param amount Amount to credit.
     */
    function addAmountToUser(
        address user,
        address token,
        uint256 amount
    ) external {
        if (listStatus.current != 0x00) _verifyTokenInteractionAllowance(token);

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

    //██ Total Supply Management ████████████████████████████████████████

    function proposeDeleteTotalSupply() external onlyAdmin {
        if (
            currentSupply < (evvmMetadata.totalSupply * 9999) / 10000 ||
            evvmMetadata.totalSupply == type(uint256).max
        ) revert Error.MaxSupplyDeletionNotAllowed();

        timeToDeleteMaxSupply = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    function rejectDeleteTotalSupply() external onlyAdmin {
        timeToDeleteMaxSupply = 0;
    }

    function acceptDeleteTotalSupply() external onlyAdmin {
        if (block.timestamp < timeToDeleteMaxSupply)
            revert Error.ProposalNotReadyToAccept();

        evvmMetadata.totalSupply = type(uint256).max;
    }

    //██ Reward distribution ████████████████████████████████████████

    function proposeChangeBaseRewardAmount(
        uint256 newBaseReward
    ) external onlyAdmin {
        if (
            evvmMetadata.totalSupply != type(uint256).max ||
            newBaseReward >= evvmMetadata.reward
        ) revert Error.BaseRewardIncreaseNotAllowed();
        proposalChangeReward = newBaseReward;
        timeToAcceptChangeReward = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    function rejectChangeBaseRewardAmount() external onlyAdmin {
        proposalChangeReward = 0;
        timeToAcceptChangeReward = 0;
    }

    function acceptChangeBaseRewardAmount() external onlyAdmin {
        if (block.timestamp < timeToAcceptChangeReward)
            revert Error.ProposalNotReadyToAccept();

        evvmMetadata.reward = proposalChangeReward;
        proposalChangeReward = 0;
        timeToAcceptChangeReward = 0;
    }

    function proposeChangeRewardFlowDistribution() external onlyAdmin {
        if (currentSupply < (evvmMetadata.totalSupply * 9999) / 10000)
            revert Error.RewardFlowDistributionChangeNotAllowed();

        rewardFlowDistribution.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    function rejectChangeRewardFlowDistribution() external onlyAdmin {
        rewardFlowDistribution.timeToAccept = 0;
    }

    function acceptChangeRewardFlowDistribution() external onlyAdmin {
        if (block.timestamp < rewardFlowDistribution.timeToAccept)
            revert Error.ProposalNotReadyToAccept();

        rewardFlowDistribution.flag = !rewardFlowDistribution.flag;
        rewardFlowDistribution.timeToAccept = 0;
    }

    //██ List state Management ████████████████████████████████████████

    function proposeListStatus(bytes1 newStatus) external onlyAdmin {
        if (uint8(newStatus) >= uint8(0x03)) revert Error.InvalidListStatus();

        listStatus.proposal = newStatus;
        listStatus.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    function rejectListStatusProposal() external onlyAdmin {
        listStatus.proposal = 0x00;
        listStatus.timeToAccept = 0;
    }

    function acceptListStatusProposal() external onlyAdmin {
        if (block.timestamp < listStatus.timeToAccept)
            revert Error.ProposalNotReadyToAccept();

        listStatus.current = listStatus.proposal;
        listStatus.proposal = 0x00;
        listStatus.timeToAccept = 0;
    }

    function setTokenStatusOnAllowList(
        address token,
        bool status
    ) external onlyAdmin {
        allowList[token] = status;
    }

    function setTokenStatusOnDenyList(
        address token,
        bool status
    ) external onlyAdmin {
        denyList[token] = status;
    }

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
            revert Error.ProposalNotReadyToAccept();

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
            revert Error.ProposalNotReadyToAccept();

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
     * @notice Triggers era transition: advances the era threshold, halves the base reward, and sends a random bonus to the caller.
     * @dev Callable by anyone when totalSupply exceeds the current era threshold.
     */
    function recalculateReward() public {
        if (
            evvmMetadata.totalSupply > evvmMetadata.eraTokens &&
            evvmMetadata.totalSupply != type(uint256).max
        ) {
            evvmMetadata.eraTokens += ((evvmMetadata.totalSupply -
                evvmMetadata.eraTokens) / 2);
            balances[msg.sender][evvmMetadata.principalTokenAddress] +=
                evvmMetadata.reward *
                _getRandom(1, 5083);
            evvmMetadata.reward = evvmMetadata.reward / 2;
        } else {
            revert();
        }
    }

    //░▒▓█ Staking Integration Functions █████████████████████████████████████████████████▓▒░

    /**
     * @notice Sets staker status for a user. Restricted to the staking contract.
     * @param user Address to update.
     * @param answer Staker status flag.
     */
    function pointStaker(address user, bytes1 answer) public {
        if (msg.sender != stakingContractAddress) revert();

        stakerList[user] = answer;
    }

    //░▒▓█ View Functions █████████████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Returns the complete EVVM metadata configuration.
     * @return EvvmMetadata struct with token info, rewards, and supply state.
     */
    function getEvvmMetadata()
        external
        view
        returns (Structs.EvvmMetadata memory)
    {
        return evvmMetadata;
    }

    /**
     * @notice Returns the sentinel address used to track Principal Token balances.
     */
    function getPrincipalTokenAddress() external view returns (address) {
        return evvmMetadata.principalTokenAddress;
    }

    /// @notice Returns the sentinel address for native ETH (address(0)).
    function getETHAddress() external pure returns (address) {
        return ETH_ADDRESS;
    }

    /**
     * @notice Returns address(0), the sentinel used for the native chain currency in balance mappings.
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
     * @notice Gets the timestamp before which the EVVM ID can be changed
     * @dev Returns the window limit for modifying the EvvmID after deployment or last change
     * @return Timestamp until which the EvvmID can be modified
     */
    function getWindowTimeToChangeEvvmID() external view returns (uint256) {
        return windowTimeToChangeEvvmID;
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
     * @notice Gets the authorized treasury contract address
     * @dev Returns the address that can perform privileged balance operations
     * @return Address of the integrated Treasury contract
     */
    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
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
     * @notice Gets the staker status flag value
     * @dev Returns the bytes1 constant used to mark an address as a registered staker
     * @return The FLAG_IS_STAKER constant value
     */
    function getFlagIsStaker() external pure returns (bytes1) {
        return FLAG_IS_STAKER;
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
     * @notice Returns the current reward amount and pending change proposal details.
     */
    function getFullDetailReward()
        public
        view
        returns (ProposalStructs.UintTypeProposal memory)
    {
        return
            ProposalStructs.UintTypeProposal({
                current: evvmMetadata.reward,
                proposal: proposalChangeReward,
                timeToAccept: timeToAcceptChangeReward
            });
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
     * @notice Gets the current supply of the Principal Token in circulation
     * @dev Returns the current circulating supply used for reward recalculations
     */
    function getCurrentSupply() public view returns (uint256) {
        return currentSupply;
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
     * @notice Returns the current implementation and pending upgrade proposal details.
     */
    function getFullDetailImplementation()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return
            ProposalStructs.AddressTypeProposal({
                current: currentImplementation,
                proposal: proposalImplementation,
                timeToAccept: timeToAcceptImplementation
            });
    }

    /**
     * @notice Gets the time delay required to accept an implementation upgrade proposal
     * @dev Returns the constant delay period for implementation upgrades (30 days)
     * @return Time delay in seconds for accepting implementation proposals
     */
    function getTimeToAcceptImplementation() external pure returns (uint256) {
        return TIME_TO_ACCEPT_IMPLEMENTATION;
    }

    /**
     * @notice Gets the current admin address
     * @dev Returns the address with administrative privileges over the contract
     * @return Address of the current admin
     */
    function getCurrentAdmin() public view returns (address) {
        return admin.current;
    }

    function getFullDetailAdmin()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return admin;
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
     * @notice Returns the status of an async nonce: 0x00 (available), 0x01 (used), 0x02 (reserved).
     * @param user User who owns the nonce.
     * @param nonce Nonce to query.
     * @return Status byte.
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
     * @notice Returns the active UserValidator and pending proposal details.
     */
    function getFullDetailUserValidator()
        public
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return userValidatorAddress;
    }

    /**
     * @notice Returns the current token restriction mode: 0x00 (none), 0x01 (denylist), 0x02 (allowlist).
     */
    function getCurrentListStatus() public view returns (bytes1) {
        return listStatus.current;
    }

    /**
     * @notice Gets comprehensive token list status details
     * @dev Returns current list status along with pending proposal info
     */
    function getFullDetailListStatus()
        public
        view
        returns (ProposalStructs.Bytes1TypeProposal memory)
    {
        return listStatus;
    }

    /**
     * @notice Returns whether a token is on the allowlist.
     */
    function getAllowListStatus(address token) public view returns (bool) {
        return allowList[token];
    }

    /**
     * @notice Returns whether a token is on the denylist.
     */
    function getDenyListStatus(address token) public view returns (bool) {
        return denyList[token];
    }

    /**
     * @notice Returns true if staker reward distribution is currently active.
     */
    function getRewardFlowDistributionFlag() public view returns (bool) {
        return rewardFlowDistribution.flag;
    }

    /**
     * @notice Returns the reward flow distribution flag and pending proposal details.
     */
    function getFullDetailRewardFlowDistribution()
        public
        view
        returns (ProposalStructs.BoolTypeProposal memory)
    {
        return rewardFlowDistribution;
    }

    /**
     * @notice Returns the timestamp after which the max supply cap can be removed.
     */
    function getTimeToDeleteMaxSupply() public view returns (uint256) {
        return timeToDeleteMaxSupply;
    }

    /**
     * @notice Gets the time delay required to accept a governance proposal
     * @dev Returns the constant delay period for admin, validator, list status, and reward proposals (1 day)
     * @return Time delay in seconds for accepting governance proposals
     */
    function getTimeToAcceptProposal() external pure returns (uint256) {
        return TIME_TO_ACCEPT_PROPOSAL;
    }

    //██ User Validation █████████████████████████████████████████████

    /**
     * @notice Returns whether a user is permitted to execute transactions.
     * @dev Delegates to UserValidator if configured; allows all if none is set.
     * @param user Address to check.
     * @return True if execution is allowed.
     */
    function canExecuteUserTransaction(
        address user
    ) public view returns (bool) {
        if (userValidatorAddress.current == address(0)) return true;
        return UserValidator(userValidatorAddress.current).canExecute(user);
    }

    //░▒▓█ Internal Functions █████████████████████████████████████████████████████▓▒░

    /**
     * @notice Returns a pseudo-random number in [min, max]. Not suitable for security-critical use.
     * @param min Minimum value (inclusive).
     * @param max Maximum value (inclusive).
     */
    function _getRandom(
        uint256 min,
        uint256 max
    ) internal view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    tx.origin,
                    gasleft()
                )
            )
        );

        return min + (randomHash % (max - min + 1));
    }

    //██ Balance Management █████████████████████████████████████████████

    /**
     * @notice Validates balance and transfers tokens between two accounts.
     * @param from Sender address.
     * @param to Recipient address.
     * @param token Token address.
     * @param value Amount to transfer.
     */
    function _updateBalance(
        address from,
        address to,
        address token,
        uint256 value
    ) internal {
        if (listStatus.current != 0x00) _verifyTokenInteractionAllowance(token);

        uint256 fromBalance = balances[from][token];
        if (fromBalance < value) revert Error.InsufficientBalance();

        unchecked {
            balances[from][token] = fromBalance - value;
            balances[to][token] += value;
        }
    }

    /**
     * @notice Distributes Principal Token rewards to a staker.
     * @param user Staker address.
     * @param amount Reward multiplier (typically number of transactions processed).
     */
    function _giveReward(address user, uint256 amount) internal {
        if (
            !rewardFlowDistribution.flag ||
            currentSupply >= evvmMetadata.totalSupply
        ) return;

        uint256 principalReward = evvmMetadata.reward * amount;
        balances[user][evvmMetadata.principalTokenAddress] += principalReward;
        currentSupply += principalReward;
    }

    /**
     * @notice Reverts if the token is restricted under the current list policy.
     */
    function _verifyTokenInteractionAllowance(address token) internal view {
        if (
            (listStatus.current == 0x01 && !allowList[token]) ||
            (listStatus.current == 0x02 && denyList[token])
        ) revert Error.TokenIsDeniedForExecution();
    }
}
