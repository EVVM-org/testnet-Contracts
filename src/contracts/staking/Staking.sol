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
 * @notice This contract manages the staking mechanism for the EVVM ecosystem
 * @dev Handles presale staking, public staking, and service staking with time locks and signature verification
 *
 * The contract supports three types of staking:
 * 1. Golden Staking: Exclusive to the goldenFisher address
 * 2. Presale Staking: Limited to 800 presale users with 2 staking token limit
 * 3. Public Staking: Open to all users when enabled
 * 4. Service Staking: Allows smart contracts to stake on behalf of users
 *
 * Key features:
 * - Time-locked unstaking mechanisms
 * - Signature-based authorization
 * - Integration with EVVM core contract for payments and rewards
 * - Estimator integration for yield calculations
 */

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {IEstimator} from "@evvm/testnet-contracts/interfaces/IEstimator.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";
import {
    StakingStructs
} from "@evvm/testnet-contracts/contracts/staking/lib/StakingStructs.sol";
import {ErrorsLib} from "./lib/ErrorsLib.sol";
import {SignatureUtils} from "./lib/SignatureUtils.sol";

contract Staking is AsyncNonce, StakingStructs {
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;

    /// @dev Address of the EVVM core contract
    address private EVVM_ADDRESS;

    /// @dev Maximum number of presale stakers allowed
    uint256 private constant LIMIT_PRESALE_STAKER = 800;
    /// @dev Current count of registered presale stakers
    uint256 private presaleStakerCount;
    /// @dev Price of one staking main token (5083 main token = 1 staking)
    uint256 private constant PRICE_OF_STAKING = 5083 * (10 ** 18);

    /// @dev Address representing the principal Principal Token
    address private constant PRINCIPAL_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    /// @dev Admin address management with proposal system
    AddressTypeProposal private admin;
    /// @dev Golden Fisher address management with proposal system
    AddressTypeProposal private goldenFisher;
    /// @dev Estimator contract address management with proposal system
    AddressTypeProposal private estimatorAddress;
    /// @dev Time delay for regular staking after unstaking
    UintTypeProposal private secondsToUnlockStaking;
    /// @dev Time delay for full unstaking (21 days default)
    UintTypeProposal private secondsToUnllockFullUnstaking;
    /// @dev Flag to enable/disable presale staking
    BoolTypeProposal private allowPresaleStaking;
    /// @dev Flag to enable/disable public staking
    BoolTypeProposal private allowPublicStaking;
    /// @dev Variable to store service staking metadata
    ServiceStakingMetadata private serviceStakingData;

    /// @dev One-time setup breaker for estimator and EVVM addresses
    bytes1 private breakerSetupEstimatorAndEvvm;

    /// @dev Mapping to store presale staker metadata
    mapping(address => presaleStakerMetadata) private userPresaleStaker;

    /// @dev Mapping to store complete staking history for each user
    mapping(address => HistoryMetadata[]) private userHistory;

    IEvvm private evvm;
    IEstimator private estimator;

    /// @dev Modifier to verify access to admin functions
    modifier onlyOwner() {
        if (msg.sender != admin.actual) revert ErrorsLib.SenderIsNotAdmin();

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

        if (size == 0) revert ErrorsLib.AddressIsNotAService();

        _;
    }

    /**
     * @notice Contract constructor
     * @dev Initializes the staking contract with admin and golden fisher addresses
     * @param initialAdmin Address that will have admin privileges
     * @param initialGoldenFisher Address that will have golden fisher privileges
     */
    constructor(address initialAdmin, address initialGoldenFisher) {
        admin.actual = initialAdmin;

        goldenFisher.actual = initialGoldenFisher;

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

        secondsToUnlockStaking.actual = 0;

        secondsToUnllockFullUnstaking.actual = 5 days;

        breakerSetupEstimatorAndEvvm = 0x01;
    }

    /**
     * @notice One-time setup function for estimator and EVVM addresses
     * @dev Can only be called once during contract initialization
     * @param _estimator Address of the Estimator contract
     * @param _evvm Address of the EVVM core contract
     */
    function _setupEstimatorAndEvvm(
        address _estimator,
        address _evvm
    ) external {
        if (breakerSetupEstimatorAndEvvm == 0x00) revert();

        estimatorAddress.actual = _estimator;
        EVVM_ADDRESS = _evvm;
        breakerSetupEstimatorAndEvvm = 0x00;
        evvm = IEvvm(_evvm);
        estimator = IEstimator(_estimator);
    }

    /**
     * @notice Allows the golden fisher to stake/unstake with synchronized EVVM nonces
     * @dev Only the golden fisher address can call this function
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function goldenStaking(
        bool isStaking,
        uint256 amountOfStaking,
        bytes memory signature_EVVM
    ) external {
        if (msg.sender != goldenFisher.actual)
            revert ErrorsLib.SenderIsNotGoldenFisher();

        stakingBaseProcess(
            AccountMetadata({Address: goldenFisher.actual, IsAService: false}),
            isStaking,
            amountOfStaking,
            0,
            evvm.getNextCurrentSyncNonce(msg.sender),
            false,
            signature_EVVM
        );
    }

    /**
     * @notice Allows presale users to stake/unstake with a limit of 2 staking tokens
     * @dev Only registered presale users can call this function when presale staking is enabled
     * @param user Address of the user performing the staking operation
     * @param isStaking True for staking, false for unstaking
     * @param nonce Unique nonce for this staking operation
     * @param signature Signature proving authorization for this staking operation
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function presaleStaking(
        address user,
        bool isStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        if (!allowPresaleStaking.flag)
            revert ErrorsLib.PresaleStakingDisabled();

        if (
            !SignatureUtils.verifyMessageSignedForStake(
                evvm.getEvvmID(),
                user,
                false,
                isStaking,
                1,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnStaking();

        verifyAsyncNonce(user, nonce);

        presaleClaims(isStaking, user);

        stakingBaseProcess(
            AccountMetadata({Address: user, IsAService: false}),
            isStaking,
            1,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        markAsyncNonceAsUsed(user, nonce);
    }

    /**
     * @notice Internal function to manage presale staking limits and permissions
     * @dev Enforces the 2 staking token limit for presale users and tracks staking amounts
     * @param _isStaking True for staking (increments count), false for unstaking (decrements count)
     * @param _user Address of the presale user
     */
    function presaleClaims(bool _isStaking, address _user) internal {
        if (allowPublicStaking.flag) {
            revert ErrorsLib.PresaleStakingDisabled();
        } else {
            if (userPresaleStaker[_user].isAllow) {
                if (_isStaking) {
                    // staking

                    if (userPresaleStaker[_user].stakingAmount >= 2)
                        revert ErrorsLib.UserPresaleStakerLimitExceeded();

                    userPresaleStaker[_user].stakingAmount++;
                } else {
                    // unstaking

                    if (userPresaleStaker[_user].stakingAmount == 0)
                        revert ErrorsLib.UserPresaleStakerLimitExceeded();

                    userPresaleStaker[_user].stakingAmount--;
                }
            } else {
                revert ErrorsLib.UserIsNotPresaleStaker();
            }
        }
    }

    /**
     * @notice Allows any user to stake/unstake when public staking is enabled
     * @dev Requires signature verification and handles nonce management
     * @param user Address of the user performing the staking operation
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param nonce Unique nonce for this staking operation
     * @param signature Signature proving authorization for this staking operation
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function publicStaking(
        address user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        if (!allowPublicStaking.flag) revert ErrorsLib.PublicStakingDisabled();

        if (
            !SignatureUtils.verifyMessageSignedForStake(
                evvm.getEvvmID(),
                user,
                true,
                isStaking,
                amountOfStaking,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnStaking();

        verifyAsyncNonce(user, nonce);

        stakingBaseProcess(
            AccountMetadata({Address: user, IsAService: false}),
            isStaking,
            amountOfStaking,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        markAsyncNonceAsUsed(user, nonce);
    }

    /**
     * @notice Prepares a service/contract account for staking by recording pre-staking state
     * @dev First step in the service staking process. Must be followed by payment via caPay and confirmServiceStaking in the same transaction
     * @param amountOfStaking Amount of staking tokens the service intends to stake
     *
     * Service Staking Process:
     * 1. Call prepareServiceStaking(amount) - Records balances and metadata
     * 2. Use EVVM.caPay() to transfer the required Principal Tokens to this contract
     * 3. Call confirmServiceStaking() - Validates payment and completes staking
     *
     * @dev All three steps MUST occur in the same transaction or the staking will fail
     * @dev CRITICAL WARNING: If the process is not completed properly (especially if caPay is called
     *      but confirmServiceStaking is not), the Principal Tokens will remain locked in the staking
     *      contract with no way to recover them. The service will lose the tokens permanently.
     * @dev Only callable by contract accounts (services), not EOAs
     */
    function prepareServiceStaking(uint256 amountOfStaking) external onlyCA {
        serviceStakingData = ServiceStakingMetadata({
            service: msg.sender,
            timestamp: block.timestamp,
            amountOfStaking: amountOfStaking,
            amountServiceBeforeStaking: evvm.getBalance(
                msg.sender,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountStakingBeforeStaking: evvm.getBalance(
                address(this),
                PRINCIPAL_TOKEN_ADDRESS
            )
        });
    }

    /**
     * @notice Confirms and completes the service staking operation after payment verification
     * @dev Final step in service staking. Validates that payment was made correctly and completes the staking process
     *
     * Validation checks:
     * - Service balance decreased by the exact staking cost
     * - Staking contract balance increased by the exact staking cost
     * - Operation occurs in the same transaction as prepareServiceStaking
     * - Caller matches the service that initiated the preparation
     *
     * @dev Only callable by the same contract that called prepareServiceStaking
     * @dev Must be called in the same transaction as prepareServiceStaking
     */
    function confirmServiceStaking() external onlyCA {
        uint256 totalStakingRequired = PRICE_OF_STAKING *
            serviceStakingData.amountOfStaking;

        uint256 actualServiceBalance = evvm.getBalance(
            msg.sender,
            PRINCIPAL_TOKEN_ADDRESS
        );

        uint256 actualStakingBalance = evvm.getBalance(
            address(this),
            PRINCIPAL_TOKEN_ADDRESS
        );

        if (
            serviceStakingData.amountServiceBeforeStaking -
                totalStakingRequired !=
            actualServiceBalance &&
            serviceStakingData.amountStakingBeforeStaking +
                totalStakingRequired !=
            actualStakingBalance
        )
            revert ErrorsLib.ServiceDoesNotFulfillCorrectStakingAmount(
                totalStakingRequired
            );

        if (serviceStakingData.timestamp != block.timestamp)
            revert ErrorsLib.ServiceDoesNotStakeInSameTx();

        if (serviceStakingData.service != msg.sender)
            revert ErrorsLib.AddressMismatch();

        stakingBaseProcess(
            AccountMetadata({Address: msg.sender, IsAService: true}),
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
            AccountMetadata({Address: msg.sender, IsAService: true}),
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
     * @param nonce_EVVM Nonce for EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for EVVM contract transaction
     */
    function stakingBaseProcess(
        AccountMetadata memory account,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) internal {
        uint256 auxSMsteBalance;

        if (isStaking) {
            if (
                getTimeToUserUnlockStakingTime(account.Address) >
                block.timestamp
            ) revert ErrorsLib.AddressMustWaitToStakeAgain();

            if (!account.IsAService)
                makePay(
                    account.Address,
                    (PRICE_OF_STAKING * amountOfStaking),
                    priorityFee_EVVM,
                    priorityFlag_EVVM,
                    nonce_EVVM,
                    signature_EVVM
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
                ) revert ErrorsLib.AddressMustWaitToFullUnstake();

                evvm.pointStaker(account.Address, 0x00);
            }

            if (priorityFee_EVVM != 0 && !account.IsAService)
                makePay(
                    account.Address,
                    priorityFee_EVVM,
                    0,
                    priorityFlag_EVVM,
                    nonce_EVVM,
                    signature_EVVM
                );

            auxSMsteBalance =
                userHistory[account.Address][
                    userHistory[account.Address].length - 1
                ].totalStaked -
                amountOfStaking;

            makeCaPay(
                PRINCIPAL_TOKEN_ADDRESS,
                account.Address,
                (PRICE_OF_STAKING * amountOfStaking)
            );
        }

        userHistory[account.Address].push(
            HistoryMetadata({
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
                PRINCIPAL_TOKEN_ADDRESS,
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
                        PRINCIPAL_TOKEN_ADDRESS,
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
     * @param priorityFlag True for async payment, false for sync payment
     * @param nonce Nonce for the EVVM transaction
     * @param signature Signature authorizing the payment
     */
    function makePay(
        address user,
        uint256 amount,
        uint256 priorityFee,
        bool priorityFlag,
        uint256 nonce,
        bytes memory signature
    ) internal {
        evvm.pay(
            user,
            address(this),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            address(this),
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
        if (presaleStakerCount > LIMIT_PRESALE_STAKER) {
            revert();
        }
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
            if (presaleStakerCount > LIMIT_PRESALE_STAKER) {
                revert();
            }
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
        if (
            msg.sender != admin.proposal || admin.timeToAccept > block.timestamp
        ) {
            revert();
        }
        admin.actual = admin.proposal;
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
        if (goldenFisher.timeToAccept > block.timestamp) {
            revert();
        }
        goldenFisher.actual = goldenFisher.proposal;
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
        if (secondsToUnlockStaking.timeToAccept > block.timestamp) {
            revert();
        }
        secondsToUnlockStaking.actual = secondsToUnlockStaking.proposal;
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
        if (secondsToUnllockFullUnstaking.timeToAccept > block.timestamp) {
            revert();
        }
        secondsToUnllockFullUnstaking.actual = secondsToUnllockFullUnstaking
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
        if (allowPublicStaking.timeToAccept > block.timestamp) {
            revert();
        }
        allowPublicStaking = BoolTypeProposal({
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
        if (allowPresaleStaking.timeToAccept > block.timestamp) revert();

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
        if (estimatorAddress.timeToAccept > block.timestamp) {
            revert();
        }
        estimatorAddress.actual = estimatorAddress.proposal;
        estimatorAddress.proposal = address(0);
        estimatorAddress.timeToAccept = 0;
        estimator = IEstimator(estimatorAddress.actual);
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // View Functions - Public Data Access
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Returns the complete staking history for an address
     * @dev Returns an array of all staking transactions and rewards for the user
     * @param _account Address to query the history for
     * @return Array of HistoryMetadata containing all transactions
     */
    function getAddressHistory(
        address _account
    ) public view returns (HistoryMetadata[] memory) {
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
     * @return HistoryMetadata of the transaction at the specified index
     */
    function getAddressHistoryByIndex(
        address _account,
        uint256 _index
    ) public view returns (HistoryMetadata memory) {
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
                    secondsToUnllockFullUnstaking.actual;
            }
        }

        return
            userHistory[_account][0].timestamp +
            secondsToUnllockFullUnstaking.actual;
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
                secondsToUnlockStaking.actual;
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
        return secondsToUnllockFullUnstaking.actual;
    }

    /**
     * @notice Returns the current time delay for regular staking operations
     * @dev Users must wait this many seconds after unstaking before they can stake again
     * @return Number of seconds required to wait between unstaking and staking
     */
    function getSecondsToUnlockStaking() external view returns (uint256) {
        return secondsToUnlockStaking.actual;
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
        return goldenFisher.actual;
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
        return estimatorAddress.actual;
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
     * @return BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllowPublicStaking()
        external
        view
        returns (BoolTypeProposal memory)
    {
        return allowPublicStaking;
    }

    /**
     * @notice Returns the complete presale staking configuration and status
     * @dev Includes current flag state and any pending changes with timestamps
     * @return BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllowPresaleStaking()
        external
        view
        returns (BoolTypeProposal memory)
    {
        return allowPresaleStaking;
    }

    /**
     * @notice Gets the unique identifier string for this EVVM instance
     * @dev Returns the EvvmID used for distinguishing different EVVM deployments
     * @return Unique EvvmID string
     */
    function getEvvmID() external view returns (uint256) {
        return IEvvm(EVVM_ADDRESS).getEvvmID();
    }

    /**
     * @notice Returns the address of the EVVM core contract
     * @dev The EVVM contract handles payments and staker registration
     * @return Address of the EVVM core contract
     */
    function getEvvmAddress() external view returns (address) {
        return EVVM_ADDRESS;
    }

    /**
     * @notice Returns the address representing the Principal Token
     * @dev This is a constant address used to represent the principal token
     * @return Address representing the Principal Token (0x...0001)
     */
    function getMateAddress() external pure returns (address) {
        return PRINCIPAL_TOKEN_ADDRESS;
    }

    /**
     * @notice Returns the current admin/owner address
     * @dev The admin has full control over contract parameters and governance
     * @return Address of the current contract admin
     */
    function getOwner() external view returns (address) {
        return admin.actual;
    }
}
