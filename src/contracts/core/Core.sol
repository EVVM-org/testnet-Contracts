// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
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
                                                             
 * @title EVVM Core Contract
 * @author Mate labs
 * @notice Core payment processing and token management for EVVM ecosystem
 */

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    CoreStorage
} from "@evvm/testnet-contracts/contracts/core/lib/CoreStorage.sol";
import {
    CoreError as Error
} from "@evvm/testnet-contracts/library/errors/CoreError.sol";
import {
    CoreHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/CoreHashUtils.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
import {CAUtils} from "@evvm/testnet-contracts/library/utils/CAUtils.sol";
import {
    IUserValidator
} from "@evvm/testnet-contracts/interfaces/IUserValidator.sol";
import {
    SignatureRecover
} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";

contract Core is CoreStorage {
    /**
     * @notice Access control modifier restricting function calls to the current admin
     * @dev Validates that msg.sender matches the current admin address before function execution
     *
     * Access Control:
     * - Only the current admin can call functions with this modifier
     * - Uses the admin.current address from the storage structure
     * - Reverts with no specific error message for unauthorized calls
     *
     * Usage:
     * - Applied to critical administrative functions
     * - Protects system configuration changes
     * - Prevents unauthorized upgrades and parameter modifications
     *
     * Security:
     * - Simple but effective access control mechanism
     * - Used for proxy upgrades, admin transfers, and system configuration
     * - Part of the time-delayed governance system for critical operations
     */
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    /**
     * @notice Initializes the EVVM contract with essential configuration and token distributions
     * @dev Sets up the core system parameters, admin roles, and initial Principal Token allocations
     *
     * Critical Initial Setup:
     * - Configures admin address with full administrative privileges
     * - Sets staking contract address for reward distribution and status management
     * - Stores EVVM metadata including principal token address and reward parameters
     * - Distributes initial Principal Tokens to staking contract (2x reward amount)
     * - Registers staking contract as privileged staker with full benefits
     * - Activates breaker flag for one-time NameService and Treasury setup
     *
     * Token Distribution:
     * - Staking contract receives 2x current reward amount in Principal Tokens
     * - Enables immediate reward distribution capabilities
     * - Provides operational liquidity for staking rewards
     *
     * Security Initialization:
     * - Sets admin.current for immediate administrative access
     * - Prepares system for NameService and Treasury integration
     * - Establishes staking privileges for the staking contract
     *
     * Post-Deployment Requirements:
     * - Must call `_setupNameServiceAndTreasuryAddress()` to complete integration
     * - NameService and Treasury addresses must be configured before full operation
     * - Implementation contract should be set for proxy functionality
     *
     * @param _initialOwner Address that will have administrative privileges over the contract
     * @param _stakingContractAddress Address of the staking contract for reward distribution and staker management
     * @param _evvmMetadata Metadata structure containing principal token address, reward amounts, and system parameters
     *
     * @custom:deployment Must be followed by NameService and Treasury setup
     * @custom:security Admin address has full control over system configuration
     */
    constructor(
        address _initialOwner,
        address _stakingContractAddress,
        CoreStructs.EvvmMetadata memory _evvmMetadata
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
     * @notice One-time setup function to configure NameService and Treasury contract addresses
     * @dev Can only be called once due to breaker flag mechanism for security
     *
     * Critical Setup Process:
     * - Validates the breaker flag is active (prevents multiple calls)
     * - Sets the NameService contract address for identity resolution in payments
     * - Configures the Treasury contract address for privileged balance operations
     * - Provides initial Principal Token balance (10,000 tokens) to NameService for operations
     * - Registers NameService as a privileged staker for enhanced functionality and rewards
     *
     * Security Features:
     * - Single-use function protected by breaker flag
     * - Prevents unauthorized reconfiguration of critical system addresses
     * - Must be called during initial system deployment phase
     *
     * Initial Token Distribution:
     * - NameService receives 10,000 Principal Tokens for operational expenses
     * - NameService gains staker privileges for transaction processing
     * - Enables identity-based payment resolution throughout the ecosystem
     *
     * @param _nameServiceAddress Address of the deployed NameService contract for identity resolution
     * @param _treasuryAddress Address of the Treasury contract for balance management operations
     *
     * @custom:security Single-use function - can only be called once
     * @custom:access-control No explicit access control - relies on deployment sequence
     * @custom:integration Critical for NameService and Treasury functionality
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
     * @notice Updates the EVVM ID with a new value, restricted to admin and time-limited
     * @dev Allows the admin to change the EVVM ID within a 1-day window after deployment
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
     * @notice Fallback function implementing proxy pattern with delegatecall to implementation
     * @dev Routes all unrecognized function calls to the current implementation contract
     *
     * Proxy Mechanism:
     * - Forwards all calls not handled by this contract to the implementation
     * - Uses delegatecall to preserve storage context and msg.sender
     * - Allows for contract upgrades without changing the main contract address
     * - Maintains all state variables in the proxy contract storage
     *
     * Implementation Process:
     * 1. Validates that an implementation contract is set
     * 2. Copies all calldata to memory for forwarding
     * 3. Executes delegatecall to implementation with full gas allowance
     * 4. Copies the return data back from the implementation
     * 5. Returns the result or reverts based on implementation response
     *
     * Security Features:
     * - Reverts if no implementation is set (prevents undefined behavior)
     * - Preserves all gas for the implementation call
     * - Maintains exact return data and revert behavior from implementation
     * - Uses storage slot reading for gas efficiency
     *
     * Upgrade Compatibility:
     * - Enables seamless contract upgrades through implementation changes
     * - Preserves all existing state and user balances
     * - Allows new functionality addition without user migration
     * - Supports time-delayed upgrade governance for security
     *
     * @custom:security Requires valid implementation address
     * @custom:proxy Transparent proxy pattern implementation
     * @custom:upgrade-safe Preserves storage layout between upgrades
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
     * @notice Faucet function to add balance to a user's account for testing purposes
     * @dev This function is intended for testnet use only to provide tokens for testing
     * @param user The address of the user to receive the balance
     * @param token The address of the token contract to add balance for
     * @param quantity The amount of tokens to add to the user's balance
     */
    function addBalance(
        address user,
        address token,
        uint256 quantity
    ) external {
        balances[user][token] += quantity;
    }

    /**
     * @notice Faucet function to set point staker status for testing purposes
     * @dev This function is intended for testnet use only to configure staker points for testing
     * @param user The address of the user to set as point staker
     * @param answer The bytes1 value representing the staker status or answer
     */
    function setPointStaker(address user, bytes1 answer) external {
        stakerList[user] = answer;
    }

    //░▒▓█ Payment Functions ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Processes single payments
     *
     * Payment Flow:
     * - Validates signature authorization for the payment
     *   (if synchronous nonce, uses nextSyncUsedNonce inside
     *    the signature verification to verify the correct nonce)
     * - Checks executor permission if specified
     * - Validates synchronous nonce matches expected value
     * - Resolves recipient address (identity or direct address)
     * - If the fisher (msg.sender) is a staker:
     *  - Transfers priority fee to the fisher
     *  - Rewards the fisher with Principal tokens
     * - Updates balances and increments nonce
     *
     * @param from Address of the payment sender
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity of recipient (resolved via NameService)
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Additional fee for transaction priority (not used in non-staker payments)
     * @param nonce Transaction nonce
     * @param isAsyncExec Execution type flag (false = sync nonce, true = async nonce)
     * @param senderExecutor Address authorized to execute this payment (zero address = sender only)
     * @param signature Cryptographic signature authorizing this payment
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
     * @notice Processes multiple payments in a single transaction batch
     * @dev Executes an array of payment operations with individual success/failure tracking
     *
     * Batch Processing Features:
     * - Processes each payment independently (partial success allowed)
     * - Returns detailed results for each transaction
     * - Supports both staker and non-staker payment types
     * - Handles both sync and async nonce types per payment
     * - Provides comprehensive transaction statistics
     *
     * Payment Validation:
     * - Each payment signature is verified independently
     * - Nonce management handled per payment type (sync/async)
     * - Identity resolution performed for each recipient
     * - Balance updates executed atomically per payment
     *
     * Return Values:
     * - successfulTransactions: Count of completed payments
     * - results: Boolean array indicating success/failure for each payment
     *
     * @param batchData Array of BatchData structures containing payment details
     * @return successfulTransactions Number of payments that completed successfully
     * @return results Boolean array with success status for each payment
     */
    function batchPay(
        CoreStructs.BatchData[] memory batchData
    ) external returns (uint256 successfulTransactions, bool[] memory results) {
        bool isSenderStaker = isAddressStaker(msg.sender);
        address to_aux;
        CoreStructs.BatchData memory payment;
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
                ) != payment.from
            ) {
                results[iteration] = false;
                continue;
            }

            if (!canExecuteUserTransaction(payment.from)) {
                results[iteration] = false;
                continue;
            }

            if (payment.isAsyncExec) {
                bytes1 statusNonce = asyncNonceStatus(
                    payment.from,
                    payment.nonce
                );
                if (asyncNonceStatus(payment.from, payment.nonce) == 0x01) {
                    results[iteration] = false;
                    continue;
                }

                if (
                    statusNonce == 0x02 &&
                    asyncNonceReservedPointers[payment.from][payment.nonce] !=
                    address(this)
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
     * @notice Distributes tokens from a single sender to multiple recipients
     * @dev Efficient single-source multi-recipient payment distribution with signature verification
     *
     * Distribution Features:
     * - Single signature authorizes distribution to multiple recipients
     * - Supports both direct addresses and identity-based recipients
     * - Proportional amount distribution based on recipient configurations
     * - Integrated priority fee and staker reward system
     * - Supports both sync and async nonce management
     *
     * Verification Process:
     * - Validates single signature for entire distribution
     * - Checks total amount and priority fee against sender balance
     * - Ensures executor permissions and nonce validity
     * - Processes each recipient distribution atomically
     *
     * Staker Benefits:
     * - Executor receives priority fee (if staker)
     * - Principal Token reward based on number of successful distributions
     *
     * @param from Address of the payment sender
     * @param toData Array of recipient data with addresses/identities and amounts
     * @param token Address of the token contract to distribute
     * @param amount Total amount to distribute (must match sum of individual amounts)
     * @param priorityFee Fee amount for the transaction executor
     * @param nonce Transaction nonce for replay protection
     * @param isAsyncExec True for async nonce, false for sync nonce
     * @param senderExecutor Address authorized to execute this distribution
     * @param signature Cryptographic signature authorizing this distribution
     */
    function dispersePay(
        address from,
        CoreStructs.DispersePayMetadata[] memory toData,
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
     * - Only smart contracts (non-EOA addresses) can call this function
     * - Calling contract must have sufficient token balance
     * - No signature verification required (contract-level authorization)
     * - Used primarily for automated distributions and rewards
     *
     * Use Cases:
     * - Staking contract reward distributions
     * - NameService fee distributions
     * - Automated system payouts
     * - Cross-contract token transfers
     *
     * Security Features:
     * - Validates caller is a contract (has bytecode)
     * - Checks sufficient balance before transfer
     * - Direct balance manipulation for efficiency
     *
     * @param to Address of the token recipient
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer from calling contract
     */
    function caPay(address to, address token, uint256 amount) external {
        address from = msg.sender;

        if (!CAUtils.verifyIfCA(from)) revert Error.NotAnCA();

        _updateBalance(from, to, token, amount);

        if (isAddressStaker(msg.sender)) _giveReward(msg.sender, 1);
    }

    /**
     * @notice Contract-to-multiple-addresses payment distribution function
     * @dev Allows authorized contracts to distribute tokens to multiple recipients efficiently
     *
     * Batch Distribution Features:
     * - Single call distributes to multiple recipients
     * - Supports both direct addresses and identity resolution
     * - Validates total amount matches sum of individual distributions
     * - Optimized for contract-based automated distributions
     *
     * Authorization Model:
     * - Only smart contracts can call this function
     * - No signature verification required (contract authorization)
     * - Calling contract must have sufficient balance for total distribution
     *
     * Use Cases:
     * - Bulk reward distributions from staking contracts
     * - Multi-recipient fee distributions
     * - Batch payroll or dividend distributions
     * - Cross-contract multi-party settlements
     *
     * @param toData Array of recipient data containing addresses/identities and amounts
     * @param token Address of the token contract to distribute
     * @param amount Total amount to distribute (must equal sum of individual amounts)
     */
    function disperseCaPay(
        CoreStructs.DisperseCaPayMetadata[] memory toData,
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
     * @notice Validates signature and consumes nonce atomically
     * @dev Central coordination function for all EVVM transactions
     *
     * Validation Workflow:
     * - Verifies caller is a contract (services only)
     * - Reconstructs EIP-191 signature payload
     * - Recovers signer and validates against user address
     * - Checks user transaction permission via validator
     * - Validates and consumes nonce based on type
     *
     * Nonce Management:
     * - Async: Checks availability/reservation, marks as used
     * - Sync: Validates sequential order, increments counter
     * - Prevents replay attacks through atomic consumption
     *
     * Service Integration:
     * - Called by all EVVM services for transaction validation
     * - Service address becomes part of signature payload
     * - Ensures service-specific nonce reservations are honored
     *
     * Security Features:
     * - Atomic signature validation + nonce consumption
     * - Contract-only caller restriction
     * - UserValidator integration for transaction filtering
     * - Service-specific nonce reservation enforcement
     *
     * @param user Address that signed the transaction
     * @param hashPayload Keccak256 hash of transaction parameters
     * @param nonce Nonce value to validate and consume
     * @param isAsyncExec True for async nonce, false for sync
     * @param signature EIP-191 signature from the user
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
     *
     * @param user Address that reserved the nonce
     * @param nonce The async nonce to revoke reservation for
     */
    function revokeAsyncNonce(address user, uint256 nonce) external {
        if (asyncNonce[user][nonce]) revert Error.AsyncNonceAlreadyUsed();

        if (asyncNonceReservedPointers[user][nonce] == address(0))
            revert Error.AsyncNonceNotReserved();

        asyncNonceReservedPointers[user][nonce] = address(0);
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
     * @notice Removes tokens from a user's balance in the EVVM system
     * @dev Restricted function that can only be called by the authorized treasury contract
     *
     * Treasury Operations:
     * - Allows treasury to burn or debit tokens from user accounts
     * - Used for cross-chain bridging, penalties, or system corrections
     * - Direct balance manipulation bypasses normal transfer protections
     * - Can potentially create negative balances if not carefully managed
     *
     * Access Control:
     * - Only the registered treasury contract can call this function
     * - Reverts with SenderIsNotTreasury error for unauthorized callers
     * - Provides centralized token withdrawal mechanism
     *
     * Use Cases:
     * - Cross-chain bridge token burning
     * - Administrative penalty applications
     * - System-level token reclamations
     * - Emergency balance corrections
     *
     * Security Considerations:
     * - No underflow protection: treasury must ensure sufficient balance
     * - Can result in unexpected negative balances if misused
     * - Treasury contract should implement additional validation
     *
     * @param user Address of the user to remove tokens from
     * @param token Address of the token contract to remove balance for
     * @param amount Amount of tokens to remove from the user's balance
     *
     * @custom:access-control Only treasury contract
     * @custom:security No underflow protection - treasury responsibility
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
     * @notice Proposes a new implementation contract for the proxy with time delay
     * @dev Part of the time-delayed governance system for critical upgrades
     *
     * Upgrade Security:
     * - 30-day time delay for implementation changes
     * - Only admin can propose upgrades
     * - Allows time for community review and validation
     * - Can be rejected before acceptance deadline
     *
     * @param _newImpl Address of the new implementation contract
     */
    function proposeImplementation(address _newImpl) external onlyAdmin {
        if (_newImpl == address(0)) revert Error.IncorrectAddressInput();
        proposalImplementation = _newImpl;
        timeToAcceptImplementation =
            block.timestamp +
            TIME_TO_ACCEPT_IMPLEMENTATION;
    }

    /**
     * @notice Cancels a pending implementation upgrade proposal
     * @dev Allows admin to reject proposed upgrades before the time delay expires
     */
    function rejectUpgrade() external onlyAdmin {
        proposalImplementation = address(0);
        timeToAcceptImplementation = 0;
    }

    /**
     * @notice Accepts a pending implementation upgrade after the time delay
     * @dev Executes the proxy upgrade to the new implementation contract
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
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _newOwner Address of the proposed new admin
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
     * @notice Cancels a pending admin change proposal
     * @dev Allows current admin to reject proposed admin changes
     */
    function rejectProposalAdmin() external onlyAdmin {
        admin = ProposalStructs.AddressTypeProposal({
            current: admin.current,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    /**
     * @notice Accepts a pending admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay
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
        returns (CoreStructs.EvvmMetadata memory)
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
        return IUserValidator(userValidatorAddress.current).canExecute(user);
    }
}
