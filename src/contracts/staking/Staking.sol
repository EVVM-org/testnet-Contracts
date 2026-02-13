// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**


  /$$$$$$  /$$             /$$      /$$                  
 /$$__  $$| $$            | $$     |__/                  
| $$  \__/$$$$$$   /$$$$$$| $$   /$$/$$/$$$$$$$  /$$$$$$ 
|  $$$$$|_  $$_/  |____  $| $$  /$$| $| $$__  $$/$$__  $$
 \____  $$| $$     /$$$$$$| $$$$$$/| $| $$  \ $| $$  \ $$
 /$$  \ $$| $$ /$$/$$__  $| $$_  $$| $| $$  | $| $$  | $$
|  $$$$$$/|  $$$$|  $$$$$$| $$ \  $| $| $$  | $|  $$$$$$$
 \______/  \___/  \_______|__/  \__|__|__/  |__/\____  $$
                                                /$$  \ $$
                                               |  $$$$$$/
                                                \______/                                                                                       

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 * @title Staking Mate contract
 * @author Mate labs
 * @notice Staking mechanism for EVVM ecosystem validators

 * Security Features:
 * - EIP-191 signature verification via State.sol
 * - Async/sync nonce-based replay protection
 * - Time-locked administrative changes (1 day delay)
 * - Atomic service staking (single tx requirement)
 * - Cooldown periods prevent abuse
 *
 * History Tracking:
 * - Complete transaction history per user
 * - Records staking, unstaking, yield events
 * - Used for cooldown calculations
 * - Enables totalStaked snapshots
 *
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    StakingStructs
} from "@evvm/testnet-contracts/library/structs/StakingStructs.sol";
import {
    StakingError as Error
} from "@evvm/testnet-contracts/library/errors/StakingError.sol";
import {
    StateManagment
} from "@evvm/testnet-contracts/library/utils/service/StateManagment.sol";
import {State} from "@evvm/testnet-contracts/contracts/state/State.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
import {
    StakingHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/StakingHashUtils.sol";

contract Staking {
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /// @dev Address of the EVVM core contract
    address private EVVM_ADDRESS;

    /// @dev Maximum number of presale stakers allowed
    uint256 private constant LIMIT_PRESALE_STAKER = 800;
    /// @dev Current count of registered presale stakers
    uint256 private presaleStakerCount;
    /// @dev Price of one staking main token (5083 main token = 1 staking)
    uint256 private constant PRICE_OF_STAKING = 5083 * (10 ** 18);

    /// @dev Admin address management with proposal system
    ProposalStructs.AddressTypeProposal private admin;
    /// @dev Golden Fisher address management with proposal system
    ProposalStructs.AddressTypeProposal private goldenFisher;
    /// @dev Estimator contract address management with proposal system
    ProposalStructs.AddressTypeProposal private estimatorAddress;
    /// @dev Time delay for regular staking after unstaking
    ProposalStructs.UintTypeProposal private secondsToUnlockStaking;
    /// @dev Time delay for full unstaking (21 days default)
    ProposalStructs.UintTypeProposal private secondsToUnllockFullUnstaking;
    /// @dev Flag to enable/disable presale staking
    ProposalStructs.BoolTypeProposal private allowPresaleStaking;
    /// @dev Flag to enable/disable public staking
    ProposalStructs.BoolTypeProposal private allowPublicStaking;
    /// @dev Variable to store service staking metadata
    StakingStructs.ServiceStakingMetadata private serviceStakingData;

    /// @dev One-time setup breaker for estimator and EVVM addresses
    bytes1 private breakerSetupEstimatorAndEvvm;

    /// @dev Mapping to store presale staker metadata
    mapping(address => StakingStructs.PresaleStakerMetadata)
        private userPresaleStaker;

    /// @dev Mapping to store complete staking history for each user
    mapping(address => StakingStructs.HistoryMetadata[]) private userHistory;

    Evvm private evvm;
    Estimator private estimator;
    State private state;

    /// @dev Modifier to verify access to admin functions
    modifier onlyOwner() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    /// @dev Modifier to verify access to a contract or service account
    modifier onlyCA() {
        uint256 size;
        address callerAddress = msg.sender;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(callerAddress)
        }

        if (size == 0) revert Error.AddressIsNotAService();

        _;
    }

    /**
     * @notice Contract constructor
     * @dev Initializes the staking contract with admin and golden fisher addresses
     * @param initialAdmin Address that will have admin privileges
     * @param initialGoldenFisher Address that will have golden fisher privileges
     */
    constructor(address initialAdmin, address initialGoldenFisher) {
        admin.current = initialAdmin;

        goldenFisher.current = initialGoldenFisher;

        /**
         * @dev Because presale staking is disabled by default
         *      if you want to enable it, you need to do it via
         *      this admin functions
         *
         *      prepareChangeAllowPresaleStaking()
         *      prepareChangeAllowPublicStaking()
         *
         *      wait TIME_TO_ACCEPT_PROPOSAL
         *
         *      confirmChangeAllowPresaleStaking()
         *      confirmChangeAllowPublicStaking()
         */

        allowPublicStaking.flag = true;
        allowPresaleStaking.flag = false;

        secondsToUnlockStaking.current = 0;

        secondsToUnllockFullUnstaking.current = 5 days;

        breakerSetupEstimatorAndEvvm = 0x01;
    }

    /**
     * @notice One-time initialization of system contracts
     * @dev Sets Estimator, Evvm, and State contract addresses
     *
     * Setup Process:
     * - Can only be called once (breaker protection)
     * - Sets estimatorAddress.current
     * - Sets EVVM_ADDRESS
     * - Initializes evvm, estimator, state instances
     * - Sets breaker to 0x00 (prevents re-init)
     *
     * Integration Setup:
     * - State.sol: Nonce validation for all staking ops
     * - Evvm.sol: Payment processing for staking tokens
     * - Estimator.sol: Yield calculation for rewards
     *
     * Security:
     * - One-time initialization via breaker flag
     * - Must be called before any staking operations
     * - No access control (assumed deployment context)
     *
     * @param _estimator Address of Estimator contract
     * @param _evvm Address of Evvm core contract
     * @param _state Address of State coordinator
     */
    function initializeSystemContracts(
        address _estimator,
        address _evvm,
        address _state
    ) external {
        if (breakerSetupEstimatorAndEvvm == 0x00) revert();

        estimatorAddress.current = _estimator;
        EVVM_ADDRESS = _evvm;

        evvm = Evvm(_evvm);
        estimator = Estimator(_estimator);
        state = State(_state);
        breakerSetupEstimatorAndEvvm = 0x00;
    }

    /**
     * @notice Golden fisher exclusive staking function
     * @dev Unlimited staking with sync nonces for special
     * privileges
     *
     * Golden Fisher Privileges:
     * - Unlimited staking capacity (no 2-token limit)
     * - Uses sync nonces (isAsyncExec = false)
     * - Bypasses presale/public staking flags
     * - Direct access without signature validation
     *
     * Sync Nonce Usage:
     * - goldenFisher uses Evvm.sol sync nonces
     * - isAsync = false in stakingBaseProcess
     * - Nonces managed by Evvm.sol, not State.sol
     * - Enables tight synchronization with Evvm ops
     *
     * Evvm.sol Integration:
     * - Payment via makePay (if isStaking=true)
     * - Cost: PRICE_OF_STAKING * amountOfStaking
     * - Refund via makeCaPay (if isStaking=false)
     * - signatureEvvm for Evvm.sol payment validation
     *
     * Staking Flow:
     * - isStaking=true: Purchase staking tokens
     * - isStaking=false: Unstake and refund
     * - No cooldown or time lock restrictions
     * - History recorded in userHistory
     *
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Number of staking tokens
     * @param signatureEvvm Signature for Evvm.sol validation
     */
    function goldenStaking(
        bool isStaking,
        uint256 amountOfStaking,
        bytes memory signatureEvvm
    ) external {
        if (msg.sender != goldenFisher.current)
            revert Error.SenderIsNotGoldenFisher();

        stakingBaseProcess(
            StakingStructs.AccountMetadata({
                Address: goldenFisher.current,
                IsAService: false
            }),
            isStaking,
            amountOfStaking,
            0,
            evvm.getNextCurrentSyncNonce(msg.sender),
            false,
            signatureEvvm
        );
    }

    /**
     * @notice Presale whitelist staking with 2-token limit
     * @dev Limited staking for registered presale addresses
     *
     * Presale Requirements:
     * - allowPresaleStaking.flag must be true
     * - allowPublicStaking.flag must be false
     * - user must be in presale whitelist (isAllow)
     * - Maximum 2 staking tokens per presale user
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash generated via StakingHashUtils
     * - Prevents replay attacks
     *
     * Evvm.sol Integration:
     * - Payment via stakingBaseProcess -> makePay
     * - Cost: PRICE_OF_STAKING * 1 (fixed 1 token)
     * - Refund via makeCaPay for unstaking
     * - priorityFee_EVVM for faster processing
     *
     * Limit Enforcement:
     * - isStaking=true: Requires current < 2
     * - isStaking=false: Requires current > 0
     * - stakingAmount updated after validation
     *
     * Usage:
     * - Exclusive to presale phase
     * - Cannot run with public staking
     * - 800 total presale slots available
     *
     * @param user Address performing staking operation
     * @param isStaking True for staking, false for unstaking
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFee_EVVM Priority fee for transaction
     * @param nonceEvvm Nonce for Evvm.sol payment
     * @param signatureEvvm Signature for Evvm.sol payment
     */
    function presaleStaking(
        address user,
        bool isStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        if (!allowPresaleStaking.flag || allowPublicStaking.flag)
            revert Error.PresaleStakingDisabled();

        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForPresaleStake(isStaking, 1),
            nonce,
            true,
            signature
        );

        if (!userPresaleStaker[user].isAllow)
            revert Error.UserIsNotPresaleStaker();

        uint256 current = userPresaleStaker[user].stakingAmount;

        if (isStaking ? current >= 2 : current == 0)
            revert Error.UserPresaleStakerLimitExceeded();

        userPresaleStaker[user].stakingAmount = isStaking
            ? current + 1
            : current - 1;

        stakingBaseProcess(
            StakingStructs.AccountMetadata({Address: user, IsAService: false}),
            isStaking,
            1,
            priorityFee_EVVM,
            nonceEvvm,
            true,
            signatureEvvm
        );
    }

    /**
     * @notice Public staking open to all users
     * @dev Unlimited staking when public phase enabled
     *
     * Public Requirements:
     * - allowPublicStaking.flag must be true
     * - No whitelist or user limits
     * - Available to any address
     *
     * State.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes user, isStaking, amountOfStaking
     * - Prevents replay attacks
     *
     * Evvm.sol Integration:
     * - Payment via stakingBaseProcess -> makePay
     * - Cost: PRICE_OF_STAKING * amountOfStaking
     * - Refund via makeCaPay for unstaking
     * - priorityFee_EVVM for faster processing
     *
     * Staking Flexibility:
     * - amountOfStaking: User-specified quantity
     * - No per-user limits (unlike presale)
     * - Subject to cooldown and time lock rules
     *
     * Time Locks:
     * - Staking cooldown: secondsToUnlockStaking
     * - Full unstake lock: secondsToUnllockFullUnstaking
     * - Enforced in stakingBaseProcess
     *
     * @param user Address performing staking operation
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Number of staking tokens
     * @param nonce Async nonce for replay protection
     * @param signature Signature for State.sol validation
     * @param priorityFee_EVVM Priority fee for transaction
     * @param nonceEvvm Nonce for Evvm.sol payment
     * @param signatureEvvm Signature for Evvm.sol payment
     */
    function publicStaking(
        address user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonceEvvm,
        bytes memory signatureEvvm
    ) external {
        if (!allowPublicStaking.flag) revert Error.PublicStakingDisabled();

        state.validateAndConsumeNonce(
            user,
            Hash.hashDataForPublicStake(isStaking, amountOfStaking),
            nonce,
            true,
            signature
        );

        stakingBaseProcess(
            StakingStructs.AccountMetadata({Address: user, IsAService: false}),
            isStaking,
            amountOfStaking,
            priorityFee_EVVM,
            nonceEvvm,
            true,
            signatureEvvm
        );
    }

    /**
     * @notice Step 1: Prepare service (contract) staking
     * @dev Records pre-staking state for atomic validation
     *
     * Service Staking Process (ATOMIC - Same TX):
     * 1. prepareServiceStaking: Record balances
     * 2. Evvm.caPay: Transfer Principal Tokens
     * 3. confirmServiceStaking: Validate and complete
     *
     * CRITICAL WARNING:
     * - All 3 steps MUST occur in single transaction
     * - If incomplete, tokens permanently locked
     * - No recovery mechanism for failed process
     * - Service loses tokens if not atomic
     *
     * Metadata Recorded:
     * - service: msg.sender (contract address)
     * - timestamp: block.timestamp (atomicity check)
     * - amountOfStaking: Requested staking tokens
     * - amountServiceBeforeStaking: Service PT balance
     * - amountStakingBeforeStaking: Staking PT balance
     *
     * Evvm.sol Payment (Step 2):
     * - Service must call Evvm.caPay after this
     * - Transfer: PRICE_OF_STAKING * amountOfStaking
     * - Recipient: address(this) (Staking contract)
     * - Token: Principal Token from Evvm.sol
     *
     * Access Control:
     * - onlyCA modifier: Only contracts allowed
     * - Checks code size via assembly
     * - EOAs rejected (size == 0)
     *
     * @param amountOfStaking Number of staking tokens to acquire
     */
    function prepareServiceStaking(uint256 amountOfStaking) external onlyCA {
        serviceStakingData = StakingStructs.ServiceStakingMetadata({
            service: msg.sender,
            timestamp: block.timestamp,
            amountOfStaking: amountOfStaking,
            amountServiceBeforeStaking: evvm.getBalance(
                msg.sender,
                evvm.getPrincipalTokenAddress()
            ),
            amountStakingBeforeStaking: evvm.getBalance(
                address(this),
                evvm.getPrincipalTokenAddress()
            )
        });
    }

    /**
     * @notice Step 3: Confirm service staking after payment
     * @dev Validates payment and completes atomic staking
     *
     * Validation Checks:
     * 1. Timestamp: Must equal prepareServiceStaking tx
     *    - Ensures atomicity (same transaction)
     *    - serviceStakingData.timestamp == block.timestamp
     *
     * 2. Caller: Must match prepareServiceStaking caller
     *    - serviceStakingData.service == msg.sender
     *    - Prevents staking hijacking
     *
     * 3. Payment Amount: Validates exact transfer
     *    - Service balance decreased by exact amount
     *    - Staking balance increased by exact amount
     *    - totalStakingRequired = PRICE_OF_STAKING *
     *      amountOfStaking
     *
     * Evvm.sol Integration:
     * - Validates caPay occurred between steps 1 and 3
     * - Checks balance deltas via Evvm.getBalance
     * - Token: evvm.getPrincipalTokenAddress()
     * - Must be exact amount (no overpayment/underpayment)
     *
     * Completion:
     * - Calls stakingBaseProcess on success
     * - Records history with transaction type 0x01
     * - Updates userHistory with staking event
     * - Service becomes staker (isAddressStaker = true)
     *
     * Error Cases:
     * - ServiceDoesNotStakeInSameTx: timestamp mismatch
     * - AddressMismatch: caller mismatch
     * - ServiceDoesNotFulfillCorrectStakingAmount:
     *   payment incorrect
     *
     * Access Control:
     * - onlyCA modifier: Only contracts allowed
     */
    function confirmServiceStaking() external onlyCA {
        uint256 totalStakingRequired = PRICE_OF_STAKING *
            serviceStakingData.amountOfStaking;

        if (
            serviceStakingData.amountServiceBeforeStaking -
                totalStakingRequired !=
            evvm.getBalance(msg.sender, evvm.getPrincipalTokenAddress()) &&
            serviceStakingData.amountStakingBeforeStaking +
                totalStakingRequired !=
            evvm.getBalance(address(this), evvm.getPrincipalTokenAddress())
        )
            revert Error.ServiceDoesNotFulfillCorrectStakingAmount(
                totalStakingRequired
            );

        if (serviceStakingData.timestamp != block.timestamp)
            revert Error.ServiceDoesNotStakeInSameTx();

        if (serviceStakingData.service != msg.sender)
            revert Error.AddressMismatch();

        stakingBaseProcess(
            StakingStructs.AccountMetadata({
                Address: msg.sender,
                IsAService: true
            }),
            true,
            serviceStakingData.amountOfStaking,
            0,
            0,
            false,
            ""
        );
    }

    /**
     * @notice Allows a service/contract account to unstake their staking tokens
     * @dev Simplified unstaking process for services - no signature or payment required, just direct unstaking
     * @param amountOfStaking Amount of staking tokens to unstake
     *
     * @dev The service will receive Principal Tokens equal to: amountOfStaking * PRICE_OF_STAKING
     * @dev Subject to the same time locks as regular unstaking (21 days for full unstake)
     * @dev Only callable by contract accounts (services), not EOAs
     */
    function serviceUnstaking(uint256 amountOfStaking) external onlyCA {
        stakingBaseProcess(
            StakingStructs.AccountMetadata({
                Address: msg.sender,
                IsAService: true
            }),
            false,
            amountOfStaking,
            0,
            0,
            false,
            ""
        );
    }

    /**
     * @notice Core staking logic that handles both service and user staking operations
     * @dev Processes payments, updates history, handles time locks, and manages EVVM integration
     * @param account Metadata of the account performing the staking operation
     *                  - Address: Address of the account
     *                  - IsAService: Boolean indicating if the account is a smart contract (service) account
     * @param isStaking True for staking (requires payment), false for unstaking (provides refund)
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param priorityFee_EVVM Priority fee for EVVM transaction
     * @param nonceEvvm Nonce for EVVM contract transaction
     * @param signatureEvvm Signature for EVVM contract transaction
     */
    function stakingBaseProcess(
        StakingStructs.AccountMetadata memory account,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 priorityFee_EVVM,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) internal {
        uint256 auxSMsteBalance;

        if (isStaking) {
            if (
                getTimeToUserUnlockStakingTime(account.Address) >
                block.timestamp
            ) revert Error.AddressMustWaitToStakeAgain();

            if (!account.IsAService)
                makePay(
                    account.Address,
                    (PRICE_OF_STAKING * amountOfStaking),
                    priorityFee_EVVM,
                    isAsyncExecEvvm,
                    nonceEvvm,
                    signatureEvvm
                );

            evvm.pointStaker(account.Address, 0x01);

            auxSMsteBalance = userHistory[account.Address].length == 0
                ? amountOfStaking
                : userHistory[account.Address][
                    userHistory[account.Address].length - 1
                ].totalStaked + amountOfStaking;
        } else {
            if (amountOfStaking == getUserAmountStaked(account.Address)) {
                if (
                    getTimeToUserUnlockFullUnstakingTime(account.Address) >
                    block.timestamp
                ) revert Error.AddressMustWaitToFullUnstake();

                evvm.pointStaker(account.Address, 0x00);
            }

            if (priorityFee_EVVM != 0 && !account.IsAService)
                makePay(
                    account.Address,
                    0,
                    priorityFee_EVVM,
                    isAsyncExecEvvm,
                    nonceEvvm,
                    signatureEvvm
                );

            auxSMsteBalance =
                userHistory[account.Address][
                    userHistory[account.Address].length - 1
                ].totalStaked -
                amountOfStaking;

            makeCaPay(
                evvm.getPrincipalTokenAddress(),
                account.Address,
                (PRICE_OF_STAKING * amountOfStaking)
            );
        }

        userHistory[account.Address].push(
            StakingStructs.HistoryMetadata({
                transactionType: isStaking
                    ? bytes32(uint256(1))
                    : bytes32(uint256(2)),
                amount: amountOfStaking,
                timestamp: block.timestamp,
                totalStaked: auxSMsteBalance
            })
        );

        if (evvm.isAddressStaker(msg.sender) && !account.IsAService) {
            makeCaPay(
                evvm.getPrincipalTokenAddress(),
                msg.sender,
                (evvm.getRewardAmount() * 2) + priorityFee_EVVM
            );
        }
    }

    /**
     * @notice Allows users to claim their staking rewards (yield)
     * @dev Interacts with the Estimator contract to calculate and distribute rewards
     * @param user Address of the user claiming rewards
     * @return epochAnswer Epoch identifier for the reward calculation
     * @return tokenToBeRewarded Address of the token being rewarded
     * @return amountTotalToBeRewarded Total amount of rewards to be distributed
     * @return idToOverwriteUserHistory Index in user history to update with reward info
     * @return timestampToBeOverwritten Timestamp to record for the reward transaction
     */
    function gimmeYiel(
        address user
    )
        external
        returns (
            bytes32 epochAnswer,
            address tokenToBeRewarded,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwriteUserHistory,
            uint256 timestampToBeOverwritten
        )
    {
        if (userHistory[user].length > 0) {
            (
                epochAnswer,
                tokenToBeRewarded,
                amountTotalToBeRewarded,
                idToOverwriteUserHistory,
                timestampToBeOverwritten
            ) = estimator.makeEstimation(user);

            if (amountTotalToBeRewarded > 0) {
                makeCaPay(tokenToBeRewarded, user, amountTotalToBeRewarded);

                userHistory[user][idToOverwriteUserHistory]
                    .transactionType = epochAnswer;
                userHistory[user][idToOverwriteUserHistory]
                    .amount = amountTotalToBeRewarded;
                userHistory[user][idToOverwriteUserHistory]
                    .timestamp = timestampToBeOverwritten;

                if (evvm.isAddressStaker(msg.sender)) {
                    makeCaPay(
                        evvm.getPrincipalTokenAddress(),
                        msg.sender,
                        (evvm.getRewardAmount() * 1)
                    );
                }
            }
        }
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // Tools for Evvm Integration
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Internal function to handle payments through the EVVM contract
     * @dev Supports both synchronous and asynchronous payment modes
     * @param user Address of the user making the payment
     * @param amount Amount to be paid in Principal Tokens
     * @param priorityFee Additional priority fee for the transaction
     * @param isAsyncExec True for async payment, false for sync payment
     * @param nonce Nonce for the EVVM transaction
     * @param signature Signature authorizing the payment
     */
    function makePay(
        address user,
        uint256 amount,
        uint256 priorityFee,
        bool isAsyncExec,
        uint256 nonce,
        bytes memory signature
    ) internal {
        evvm.pay(
            user,
            address(this),
            "",
            evvm.getPrincipalTokenAddress(),
            amount,
            priorityFee,
            address(this),
            nonce,
            isAsyncExec,
            signature
        );
    }

    /**
     * @notice Internal function to handle token distributions through EVVM contract
     * @dev Used for unstaking refunds and reward distributions
     * @param tokenAddress Address of the token to be distributed
     * @param user Address of the recipient
     * @param amount Amount of tokens to distribute
     */
    function makeCaPay(
        address tokenAddress,
        address user,
        uint256 amount
    ) internal {
        evvm.caPay(user, tokenAddress, amount);
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // Administrative Functions with Time-Delayed Governance
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Adds a single address to the presale staker list
     * @dev Only admin can call this function, limited to 800 presale stakers total
     * @param _staker Address to be added to the presale staker list
     */
    function addPresaleStaker(address _staker) external onlyOwner {
        if (presaleStakerCount > LIMIT_PRESALE_STAKER)
            revert Error.LimitPresaleStakersExceeded();

        userPresaleStaker[_staker].isAllow = true;
        presaleStakerCount++;
    }

    /**
     * @notice Adds multiple addresses to the presale staker list in batch
     * @dev Only admin can call this function, limited to 800 presale stakers total
     * @param _stakers Array of addresses to be added to the presale staker list
     */
    function addPresaleStakers(address[] calldata _stakers) external onlyOwner {
        for (uint256 i = 0; i < _stakers.length; i++) {
            if (presaleStakerCount > LIMIT_PRESALE_STAKER)
                revert Error.LimitPresaleStakersExceeded();

            userPresaleStaker[_stakers[i]].isAllow = true;
            presaleStakerCount++;
        }
    }

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _newAdmin Address of the proposed new admin
     */
    function proposeAdmin(address _newAdmin) external onlyOwner {
        admin.proposal = _newAdmin;
        admin.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Rejects the current admin proposal
     * @dev Only current admin can reject the pending proposal
     */
    function rejectProposalAdmin() external onlyOwner {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts the admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay has passed
     */
    function acceptNewAdmin() external {
        if (msg.sender != admin.proposal)
            revert Error.SenderIsNotProposedAdmin();

        if (admin.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        admin.current = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Proposes a new golden fisher address with 1-day time delay
     * @dev Part of the time-delayed governance system for golden fisher changes
     * @param _goldenFisher Address of the proposed new golden fisher
     */
    function proposeGoldenFisher(address _goldenFisher) external onlyOwner {
        goldenFisher.proposal = _goldenFisher;
        goldenFisher.timeToAccept = block.timestamp + TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Rejects the current golden fisher proposal
     * @dev Only current admin can reject the pending golden fisher proposal
     */
    function rejectProposalGoldenFisher() external onlyOwner {
        goldenFisher.proposal = address(0);
        goldenFisher.timeToAccept = 0;
    }

    /**
     * @notice Accepts the golden fisher proposal after the time delay has passed
     * @dev Can only be called by the current admin after the 1-day time delay
     */
    function acceptNewGoldenFisher() external onlyOwner {
        if (goldenFisher.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        goldenFisher.current = goldenFisher.proposal;
        goldenFisher.proposal = address(0);
        goldenFisher.timeToAccept = 0;
    }

    /**
     * @notice Proposes a new time delay for staking after unstaking with 1-day time delay
     * @dev Part of the time-delayed governance system for staking unlock time changes
     * @param _secondsToUnlockStaking New number of seconds users must wait after unstaking before staking again
     */
    function proposeSetSecondsToUnlockStaking(
        uint256 _secondsToUnlockStaking
    ) external onlyOwner {
        secondsToUnlockStaking.proposal = _secondsToUnlockStaking;
        secondsToUnlockStaking.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Rejects the current staking unlock time proposal
     * @dev Only current admin can reject the pending staking unlock time proposal
     */
    function rejectProposalSetSecondsToUnlockStaking() external onlyOwner {
        secondsToUnlockStaking.proposal = 0;
        secondsToUnlockStaking.timeToAccept = 0;
    }

    /**
     * @notice Accepts the staking unlock time proposal after the time delay has passed
     * @dev Can only be called by the current admin after the 1-day time delay
     */
    function acceptSetSecondsToUnlockStaking() external onlyOwner {
        if (secondsToUnlockStaking.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        secondsToUnlockStaking.current = secondsToUnlockStaking.proposal;
        secondsToUnlockStaking.proposal = 0;
        secondsToUnlockStaking.timeToAccept = 0;
    }

    /**
     * @notice Proposes a new time delay for full unstaking operations with 1-day time delay
     * @dev Part of the time-delayed governance system for full unstaking time changes
     * @param _secondsToUnllockFullUnstaking New number of seconds users must wait for full unstaking (default: 21 days)
     */
    function prepareSetSecondsToUnllockFullUnstaking(
        uint256 _secondsToUnllockFullUnstaking
    ) external onlyOwner {
        secondsToUnllockFullUnstaking.proposal = _secondsToUnllockFullUnstaking;
        secondsToUnllockFullUnstaking.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the current full unstaking time proposal
     * @dev Only current admin can cancel the pending full unstaking time proposal
     */
    function cancelSetSecondsToUnllockFullUnstaking() external onlyOwner {
        secondsToUnllockFullUnstaking.proposal = 0;
        secondsToUnllockFullUnstaking.timeToAccept = 0;
    }

    /**
     * @notice Confirms the full unstaking time proposal after the time delay has passed
     * @dev Can only be called by the current admin after the 1-day time delay
     */
    function confirmSetSecondsToUnllockFullUnstaking() external onlyOwner {
        if (secondsToUnllockFullUnstaking.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        secondsToUnllockFullUnstaking.current = secondsToUnllockFullUnstaking
            .proposal;
        secondsToUnllockFullUnstaking.proposal = 0;
        secondsToUnllockFullUnstaking.timeToAccept = 0;
    }

    /**
     * @notice Prepares to toggle the public staking flag with 1-day time delay
     * @dev Initiates the time-delayed process to enable/disable public staking
     */
    function prepareChangeAllowPublicStaking() external onlyOwner {
        allowPublicStaking.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the pending public staking flag change
     * @dev Only current admin can cancel the pending public staking toggle
     */
    function cancelChangeAllowPublicStaking() external onlyOwner {
        allowPublicStaking.timeToAccept = 0;
    }

    /**
     * @notice Confirms and executes the public staking flag toggle after the time delay has passed
     * @dev Toggles between enabled/disabled state for public staking after 1-day delay
     */
    function confirmChangeAllowPublicStaking() external onlyOwner {
        if (allowPublicStaking.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        allowPublicStaking = ProposalStructs.BoolTypeProposal({
            flag: !allowPublicStaking.flag,
            timeToAccept: 0
        });
    }

    /**
     * @notice Prepares to toggle the presale staking flag with 1-day time delay
     * @dev Initiates the time-delayed process to enable/disable presale staking
     */
    function prepareChangeAllowPresaleStaking() external onlyOwner {
        allowPresaleStaking.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Cancels the pending presale staking flag change
     * @dev Only current admin can cancel the pending presale staking toggle
     */
    function cancelChangeAllowPresaleStaking() external onlyOwner {
        allowPresaleStaking.timeToAccept = 0;
    }

    /**
     * @notice Confirms and executes the presale staking flag toggle after the time delay has passed
     * @dev Toggles between enabled/disabled state for presale staking after 1-day delay
     */
    function confirmChangeAllowPresaleStaking() external onlyOwner {
        if (allowPresaleStaking.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        allowPresaleStaking.flag = !allowPresaleStaking.flag;
        allowPresaleStaking.timeToAccept = 0;
    }

    /**
     * @notice Proposes a new estimator contract address with 1-day time delay
     * @dev Part of the time-delayed governance system for estimator contract changes
     * @param _estimator Address of the proposed new estimator contract
     */
    function proposeEstimator(address _estimator) external onlyOwner {
        estimatorAddress.proposal = _estimator;
        estimatorAddress.timeToAccept =
            block.timestamp +
            TIME_TO_ACCEPT_PROPOSAL;
    }

    /**
     * @notice Rejects the current estimator contract proposal
     * @dev Only current admin can reject the pending estimator contract proposal
     */
    function rejectProposalEstimator() external onlyOwner {
        estimatorAddress.proposal = address(0);
        estimatorAddress.timeToAccept = 0;
    }

    /**
     * @notice Accepts the estimator contract proposal after the time delay has passed
     * @dev Can only be called by the current admin after the 1-day time delay
     */
    function acceptNewEstimator() external onlyOwner {
        if (estimatorAddress.timeToAccept > block.timestamp)
            revert Error.TimeToAcceptProposalNotReached();

        estimatorAddress.current = estimatorAddress.proposal;
        estimatorAddress.proposal = address(0);
        estimatorAddress.timeToAccept = 0;
        estimator = Estimator(estimatorAddress.current);
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // View Functions - Public Data Access
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Returns the complete staking history for an address
     * @dev Returns an array of all staking transactions and rewards for the user
     * @param _account Address to query the history for
     * @return Array of StakingStructs.HistoryMetadata containing all transactions
     */
    function getAddressHistory(
        address _account
    ) public view returns (StakingStructs.HistoryMetadata[] memory) {
        return userHistory[_account];
    }

    /**
     * @notice Returns the number of transactions in an address's staking history
     * @dev Useful for pagination or checking if an address has any staking history
     * @param _account Address to query the history size for
     * @return Number of transactions in the history
     */
    function getSizeOfAddressHistory(
        address _account
    ) public view returns (uint256) {
        return userHistory[_account].length;
    }

    /**
     * @notice Returns a specific transaction from an address's staking history
     * @dev Allows accessing individual transactions by index
     * @param _account Address to query the history for
     * @param _index Index of the transaction to retrieve (0-based)
     * @return StakingStructs.HistoryMetadata of the transaction at the specified index
     */
    function getAddressHistoryByIndex(
        address _account,
        uint256 _index
    ) public view returns (StakingStructs.HistoryMetadata memory) {
        return userHistory[_account][_index];
    }

    /**
     * @notice Returns the fixed price of one staking token in Principal Tokens
     * @dev Returns the constant price of 5083 Principal Tokens per staking
     * @return Price of one staking token in Principal Tokens (with 18 decimals)
     */
    function priceOfStaking() external pure returns (uint256) {
        return PRICE_OF_STAKING;
    }

    /**
     * @notice Calculates when a user can perform full unstaking (withdraw all tokens)
     * @dev Full unstaking requires waiting 21 days after the last time their balance reached 0
     * @param _account Address to check the unlock time for
     * @return Timestamp when full unstaking will be allowed
     */
    function getTimeToUserUnlockFullUnstakingTime(
        address _account
    ) public view returns (uint256) {
        for (uint256 i = userHistory[_account].length; i > 0; i--) {
            if (userHistory[_account][i - 1].totalStaked == 0) {
                return
                    userHistory[_account][i - 1].timestamp +
                    secondsToUnllockFullUnstaking.current;
            }
        }

        return
            userHistory[_account][0].timestamp +
            secondsToUnllockFullUnstaking.current;
    }

    /**
     * @notice Calculates when a user can stake again after unstaking
     * @dev Users must wait a configurable period after unstaking before they can stake again
     * @param _account Address to check the unlock time for
     * @return Timestamp when staking will be allowed again (0 if already allowed)
     */
    function getTimeToUserUnlockStakingTime(
        address _account
    ) public view returns (uint256) {
        uint256 lengthOfHistory = userHistory[_account].length;

        if (lengthOfHistory == 0) {
            return 0;
        }
        if (userHistory[_account][lengthOfHistory - 1].totalStaked == 0) {
            return
                userHistory[_account][lengthOfHistory - 1].timestamp +
                secondsToUnlockStaking.current;
        } else {
            return 0;
        }
    }

    /**
     * @notice Returns the current time delay for full unstaking operations
     * @dev Full unstaking requires waiting this many seconds (default: 21 days)
     * @return Number of seconds required to wait for full unstaking
     */
    function getSecondsToUnlockFullUnstaking() external view returns (uint256) {
        return secondsToUnllockFullUnstaking.current;
    }

    /**
     * @notice Returns the current time delay for regular staking operations
     * @dev Users must wait this many seconds after unstaking before they can stake again
     * @return Number of seconds required to wait between unstaking and staking
     */
    function getSecondsToUnlockStaking() external view returns (uint256) {
        return secondsToUnlockStaking.current;
    }

    /**
     * @notice Returns the current amount of staking tokens staked by a user
     * @dev Returns the total staked amount from the user's most recent transaction
     * @param _account Address to check the staked amount for
     * @return Amount of staking tokens currently staked by the user
     */
    function getUserAmountStaked(
        address _account
    ) public view returns (uint256) {
        uint256 lengthOfHistory = userHistory[_account].length;

        if (lengthOfHistory == 0) {
            return 0;
        }

        return userHistory[_account][lengthOfHistory - 1].totalStaked;
    }

    /**
     * @notice Returns the current golden fisher address
     * @dev The golden fisher has special staking privileges
     * @return Address of the current golden fisher
     */
    function getGoldenFisher() external view returns (address) {
        return goldenFisher.current;
    }

    /**
     * @notice Returns the proposed new golden fisher address (if any)
     * @dev Shows pending golden fisher changes in the governance system
     * @return Address of the proposed golden fisher (zero address if none)
     */
    function getGoldenFisherProposal() external view returns (address) {
        return goldenFisher.proposal;
    }

    /**
     * @notice Returns presale staker information for a given address
     * @dev Shows if an address is allowed for presale and how many tokens they've staked
     * @param _account Address to check presale status for
     * @return isAllow True if the address is allowed for presale staking
     * @return stakingAmount Number of staking tokens currently staked in presale (max 2)
     */
    function getPresaleStaker(
        address _account
    ) external view returns (bool, uint256) {
        return (
            userPresaleStaker[_account].isAllow,
            userPresaleStaker[_account].stakingAmount
        );
    }

    /**
     * @notice Returns the current estimator contract address
     * @dev The estimator calculates staking rewards and yields
     * @return Address of the current estimator contract
     */
    function getEstimatorAddress() external view returns (address) {
        return estimatorAddress.current;
    }

    /**
     * @notice Returns the proposed new estimator contract address (if any)
     * @dev Shows pending estimator changes in the governance system
     * @return Address of the proposed estimator contract (zero address if none)
     */
    function getEstimatorProposal() external view returns (address) {
        return estimatorAddress.proposal;
    }

    /**
     * @notice Returns the current number of registered presale stakers
     * @dev Maximum allowed is 800 presale stakers
     * @return Current count of presale stakers
     */
    function getPresaleStakerCount() external view returns (uint256) {
        return presaleStakerCount;
    }

    /**
     * @notice Returns the complete public staking configuration and status
     * @dev Includes current flag state and any pending changes with timestamps
     * @return ProposalStructs.BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllowPublicStaking()
        external
        view
        returns (ProposalStructs.BoolTypeProposal memory)
    {
        return allowPublicStaking;
    }

    /**
     * @notice Returns the complete presale staking configuration and status
     * @dev Includes current flag state and any pending changes with timestamps
     * @return ProposalStructs.BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllowPresaleStaking()
        external
        view
        returns (ProposalStructs.BoolTypeProposal memory)
    {
        return allowPresaleStaking;
    }

    /**
     * @notice Gets the unique identifier string for this EVVM instance
     * @dev Returns the EvvmID used for distinguishing different EVVM deployments
     * @return Unique EvvmID string
     */
    function getEvvmID() external view returns (uint256) {
        return evvm.getEvvmID();
    }

    /**
     * @notice Returns the address of the EVVM core contract
     * @dev The EVVM contract handles payments and staker registration
     * @return Address of the EVVM core contract
     */
    function getEvvmAddress() external view returns (address) {
        return EVVM_ADDRESS;
    }

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return state.getIfUsedAsyncNonce(user, nonce);
    }

    /**
     * @notice Returns the address representing the Principal Token
     * @dev This is a constant address used to represent the principal token
     * @return Address representing the Principal Token (0x...0001)
     */
    function getMateAddress() external view returns (address) {
        return evvm.getPrincipalTokenAddress();
    }

    /**
     * @notice Returns the current admin/owner address
     * @dev The admin has full control over contract parameters and governance
     * @return Address of the current contract admin
     */
    function getOwner() external view returns (address) {
        return admin.current;
    }
}
