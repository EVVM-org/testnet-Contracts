// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {P2PSwapHashUtils as Hash} from "@evvm/testnet-contracts/library/utils/signature/P2PSwapHashUtils.sol";
import {P2PSwapStructs as Structs} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import {P2PSwapError as Error} from "@evvm/testnet-contracts/library/errors/P2PSwapError.sol";

import {EvvmService} from "@evvm/testnet-contracts/library/EvvmService.sol";
import {CoreStructs} from "@evvm/testnet-contracts/interfaces/ICore.sol";

import {ProposalStructs} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

/**
 /$$$$$$$  /$$$$$$ /$$$$$$$  /$$$$$$
| $$__  $$/$$__  $| $$__  $$/$$__  $$
| $$  \ $|__/  \ $| $$  \ $| $$  \__//$$  /$$  /$$ /$$$$$$  /$$$$$$
| $$$$$$$/ /$$$$$$| $$$$$$$|  $$$$$$| $$ | $$ | $$|____  $$/$$__  $$
| $$____/ /$$____/| $$____/ \____  $| $$ | $$ | $$ /$$$$$$| $$  \ $$
| $$     | $$     | $$      /$$  \ $| $$ | $$ | $$/$$__  $| $$  | $$
| $$     | $$$$$$$| $$     |  $$$$$$|  $$$$$/$$$$|  $$$$$$| $$$$$$$/
|__/     |________|__/      \______/ \_____/\___/ \_______| $$____/
                                                          | $$
                                                          | $$
                                                          |__/

 * @title EVVM P2P Swap
 * @author Mate labs
 * @notice Peer-to-peer decentralized exchange for token trading within EVVM.
 * @dev Supports order book-style trading with customizable fee models.
 *      Integrates with Core.sol for asset locking and settlements, and Staking.sol for validator rewards.
 */

contract P2PSwap is EvvmService {
    /// @notice Time delay for accepting a new admin proposal (1 day).
    uint256 constant TIME_TO_ACCEPT_PROPOSAL = 1 days;
    /// @notice Current admin address with a pending proposal mechanism.
    ProposalStructs.AddressTypeProposal admin;
    /// @notice Fee split percentages in basis points (seller / service / staker).
    Structs.PercentageProposal basisPointsForReward;
    /// @notice Proportional fee rate in basis points applied to fills (500 = 5%).
    ProposalStructs.UintTypeProposal percentageFee;

    /// @notice Stores market metadata indexed by the hash of the token pair.
    mapping(bytes32 marketId => Structs.MarketInformation) marketInformation;
    /// @notice Stores orders indexed by market ID and order slot.
    mapping(bytes32 marketId => mapping(uint256 orderId => Structs.Order)) orders;

    mapping(address token => uint256 amountCollected) totalFeesCollected;

    /// @notice Restricts access to the system administrator.
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert Error.SenderIsNotAdmin();

        _;
    }

    /**
     * @notice Initializes P2PSwap with Core, Staking, and admin addresses.
     * @param _coreAddress Address of the Core contract.
     * @param _stakingAddress Address of the Staking contract.
     * @param _admin Initial admin address.
     */
    constructor(
        address _coreAddress,
        address _stakingAddress,
        address _admin
    ) EvvmService(_coreAddress, _stakingAddress) {
        admin.current = _admin;
        percentageFee.current = 500;
        basisPointsForReward = Structs.PercentageProposal({
            current: Structs.Percentage({
                seller: 5000,
                service: 4000,
                mateStaker: 1000
            }),
            proposed: Structs.Percentage({
                seller: 0,
                service: 0,
                mateStaker: 0
            }),
            proposalTime: 0
        });
    }

    /**
     * @notice Places a new sell order in the order book for a token pair.
     * @dev Locks `offeredAmount` of `offeredToken` from `user` into the contract.
     *      Assigns the order to the first available slot or opens a new one.
     *      Updates the market VWAP after insertion.
     * @param user Address of the seller creating the order.
     * @param offeredToken Token the seller is offering.
     * @param requestedToken Token the seller wants in return.
     * @param offeredAmount Total amount of `offeredToken` being offered.
     * @param requestedAmount Total amount of `requestedToken` expected for the full offer.
     * @param senderExecutor Address of the executor relaying the order action.
     * @param originExecutor Address of the origin executor for nonce validation.
     * @param nonce Async nonce authorizing this action.
     * @param signature User's ECDSA signature over the order parameters.
     * @param priorityFeePay Priority fee in `offeredToken` paid to the executor.
     * @param noncePay Async nonce authorizing the payment.
     * @param signaturePay User's ECDSA signature authorizing the payment.
     */
    function makeOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 offeredAmount,
        uint256 requestedAmount,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        if (offeredAmount == 0) revert Error.ZeroAmount();
        if (requestedAmount == 0) revert Error.ZeroAmount();
        if (offeredToken == requestedToken) revert Error.SameTokenPair();

        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForMakeOrder(
                offeredToken,
                requestedToken,
                offeredAmount,
                requestedAmount
            ),
            originExecutor,
            nonce,
            true,
            signature
        );

        requestPay(
            user,
            offeredToken,
            offeredAmount,
            priorityFeePay,
            originExecutor,
            noncePay,
            true,
            signaturePay
        );

        //we get the market id from the token pair
        bytes32 marketId = getMarketId(offeredToken, requestedToken);

        uint256 orderId;

        if (
            marketInformation[marketId].maxSlot ==
            marketInformation[marketId].ordersAvailable
        ) {
            orderId = marketInformation[marketId].maxSlot;
            marketInformation[marketId].maxSlot++;
        } else {
            for (uint256 i = 1; i < marketInformation[marketId].maxSlot; i++) {
                if (orders[marketId][i].seller == address(0)) {
                    orderId = i;
                    break;
                }
            }

            if (orderId == 0) revert Error.UnexpectedBehavior();
        }

        marketInformation[marketId].ordersAvailable++;

        // we create the order
        orders[marketId][orderId] = Structs.Order({
            seller: user,
            offeredAmount: offeredAmount,
            requestedAmount: requestedAmount,
            amountAvailable: offeredAmount
        });

        // we calculate the median price for the market and update it
        marketInformation[marketId].medianPrice = getVWAP(marketId);

        if (core.isAddressStaker(msg.sender) && priorityFeePay > 0)
            makeCaPay(msg.sender, offeredToken, priorityFeePay);

        // send some mate token reward to the executor (independent of the priorityFee the user attached)
        _rewardExecutor(msg.sender, 2);
    }

    /**
     * @notice Cancels an existing order and returns the remaining offered tokens to the seller.
     * @dev Only the original seller can cancel. Returns `amountAvailable` of `offeredToken` to `user`.
     *      Updates the market VWAP after removal.
     * @param user Address of the seller who owns the order.
     * @param offeredToken Token that was offered in the order.
     * @param requestedToken Token that was requested in the order.
     * @param orderId Slot ID of the order to cancel.
     * @param senderExecutor Address of the executor relaying the cancel action.
     * @param originExecutor Address of the origin executor for nonce validation.
     * @param nonce Async nonce authorizing this action.
     * @param signature User's ECDSA signature over the cancel parameters.
     * @param priorityFeePay Priority fee in MATE token paid to the executor (0 if none).
     * @param noncePay Async nonce authorizing the priority fee payment.
     * @param signaturePay User's ECDSA signature authorizing the priority fee payment.
     */
    function cancelOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        // we check if the order exists and if the user is the seller
        if (order.seller == address(0)) revert Error.OrderIsUnavailable();
        if (order.seller != user) revert Error.NotTheSeller();

        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForCancelOrder(offeredToken, requestedToken, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        bytes32 marketId = getMarketId(offeredToken, requestedToken);

        // we store the order in memory to save gas
        Structs.Order memory order = orders[marketId][orderId];

        if (priorityFeePay > 0)
            requestPay(
                user,
                core.getPrincipalTokenAddress(),
                0,
                priorityFeePay,
                originExecutor,
                noncePay,
                true,
                signaturePay
            );

        makeCaPay(user, offeredToken, order.amountAvailable);

        orders[marketId][orderId].seller = address(0);
        orders[marketId][orderId].amountAvailable = 0;
        marketInformation[marketId].ordersAvailable--;

        // we calculate the median price for the market and update it
        marketInformation[marketId].medianPrice = getVWAP(marketId);

        if (core.isAddressStaker(msg.sender) && priorityFeePay > 0)
            makeCaPay(
                msg.sender,
                core.getPrincipalTokenAddress(),
                priorityFeePay
            );

        _rewardExecutor(msg.sender, 2);
    }

    /**
     * @notice Fills an existing order partially or fully.
     * @dev Buyer receives `amountOut` of `offeredToken`. Payment is proportional to the order price.
     *      The fee is split: seller (50%), service (40%, stays in contract), executor (10%).
     *      Reverts if `totalPayment + fee` exceeds `amountInMax`.
     *      If the order is fully filled, the slot is freed and the order count decremented.
     * @param user Address of the buyer filling the order.
     * @param offeredToken Token the seller is offering (what the buyer receives).
     * @param requestedToken Token the seller wants in return (what the buyer pays).
     * @param orderId Slot ID of the order to fill.
     * @param amountOut Amount of `offeredToken` the buyer wants to receive.
     * @param amountInMax Maximum amount of `requestedToken` the buyer is willing to pay, including fee.
     * @param senderExecutor Address of the executor relaying the fill action.
     * @param originExecutor Address of the origin executor for nonce validation.
     * @param nonce Async nonce authorizing this action.
     * @param signature User's ECDSA signature over the dispatch parameters.
     * @param priorityFeePay Priority fee in `requestedToken` paid to the executor.
     * @param noncePay Async nonce authorizing the payment.
     * @param signaturePay User's ECDSA signature authorizing the payment.
     */
    function dispatchOrder(
        address user,
        address offeredToken,
        address requestedToken,
        uint256 orderId,
        uint256 amountOut,
        uint256 amountInMax,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        bytes32 market = getMarketId(offeredToken, requestedToken);
        Structs.Order storage order = orders[market][orderId];

        if (amountOut == 0) revert Error.ZeroAmount();
        if (amountInMax == 0) revert Error.ZeroAmount();
        if (order.seller == address(0)) revert Error.OrderIsUnavailable();

        if (order.amountAvailable < amountOut)
            revert Error.InsufficientAmountToFill();

        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForDispatchOrder(
                offeredToken,
                requestedToken,
                orderId,
                amountOut,
                amountInMax
            ),
            originExecutor,
            nonce,
            true,
            signature
        );

        uint256 netPaymentAmount = getNetPaymentAmount(
            amountOut,
            order.offeredAmount,
            order.requestedAmount
        );

        if (netPaymentAmount == 0) revert Error.InsufficientPayment();

        uint256 fee = getFeePaymentAmount(netPaymentAmount);

        uint256 totalPayment = netPaymentAmount + fee;

        if (totalPayment > amountInMax) revert Error.InsufficientPayment();

        requestPay(
            user,
            requestedToken,
            amountInMax,
            priorityFeePay,
            originExecutor,
            noncePay,
            true,
            signaturePay
        );

        orders[market][orderId].amountAvailable -= amountOut;
        marketInformation[market].medianPrice = getVWAP(market);

        uint256 sellerAmount =
            netPaymentAmount +
                applyBasisPoints(fee, basisPointsForReward.current.seller);
        uint256 executorAmount =
            priorityFeePay +
                applyBasisPoints(fee, basisPointsForReward.current.mateStaker);

        collectFees(
            requestedToken,
            applyBasisPoints(fee, basisPointsForReward.current.service)
        );

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](2);
        toData[0] = CoreStructs.DisperseCaPayMetadata(
            sellerAmount,
            order.seller
        );
        toData[1] = CoreStructs.DisperseCaPayMetadata(
            executorAmount,
            msg.sender
        );
        makeDisperseCaPay(
            toData,
            requestedToken,
            sellerAmount + executorAmount
        );

        if (amountInMax > totalPayment)
            makeCaPay(user, requestedToken, amountInMax - totalPayment);

        makeCaPay(user, offeredToken, amountOut);

        if (orders[market][orderId].amountAvailable == 0) {
            orders[market][orderId].seller = address(0);
            marketInformation[market].ordersAvailable--;
        }

        _rewardExecutor(msg.sender, 4);
    }

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

    /// @notice Cancels a pending admin change proposal.
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

    function proposeBasisPercentageFee(uint256 _newFee) external onlyAdmin {
        if (_newFee > 10_000) revert Error.IncorrectAddressInput();

        percentageFee = ProposalStructs.UintTypeProposal({
            current: percentageFee.current,
            proposal: _newFee,
            timeToAccept: block.timestamp + TIME_TO_ACCEPT_PROPOSAL
        });
    }

    function rejectProposalBasisPercentageFee() external onlyAdmin {
        percentageFee = ProposalStructs.UintTypeProposal({
            current: percentageFee.current,
            proposal: 0,
            timeToAccept: 0
        });
    }

    function acceptBasisPercentageFee() external onlyAdmin {
        if (block.timestamp < percentageFee.timeToAccept)
            revert Error.ProposalNotReadyToAccept();

        percentageFee = ProposalStructs.UintTypeProposal({
            current: percentageFee.proposal,
            proposal: 0,
            timeToAccept: 0
        });
    }

    function proposeBasisPointsForReward(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external onlyAdmin {
        if (_seller + _service + _mateStaker != 10_000)
            revert Error.InvalidBasisPoints();

        basisPointsForReward = Structs.PercentageProposal({
            current: basisPointsForReward.current,
            proposed: Structs.Percentage({
                seller: _seller,
                service: _service,
                mateStaker: _mateStaker
            }),
            proposalTime: block.timestamp + TIME_TO_ACCEPT_PROPOSAL
        });
    }

    function rejectProposalBasisPointsForReward() external onlyAdmin {
        basisPointsForReward = Structs.PercentageProposal({
            current: basisPointsForReward.current,
            proposed: Structs.Percentage({
                seller: 0,
                service: 0,
                mateStaker: 0
            }),
            proposalTime: 0
        });
    }

    function acceptBasisPointsForReward() external onlyAdmin {
        if (block.timestamp < basisPointsForReward.proposalTime)
            revert Error.ProposalNotReadyToAccept();

        basisPointsForReward = Structs.PercentageProposal({
            current: basisPointsForReward.proposed,
            proposed: Structs.Percentage({
                seller: 0,
                service: 0,
                mateStaker: 0
            }),
            proposalTime: 0
        });
    }

    /**
     * @notice Returns the deterministic market ID for a token pair.
     * @param tokenA First token of the pair.
     * @param tokenB Second token of the pair.
     * @return Market ID as a bytes32 hash.
     */
    function getMarketId(
        address tokenA,
        address tokenB
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    /**
     * @dev Applies a basis-point rate to an amount.
     * @param amount Base amount to apply the rate to.
     * @param basisPoints Rate in basis points (10_000 = 100%).
     * @return Scaled result: amount * basisPoints / 10_000.
     */
    function applyBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

    /**
     * @notice Calculates the base payment amount (excluding fee) for a partial fill.
     * @dev Uses the order's original price ratio: netPayment = amountOut * requestedAmount / offeredAmount.
     * @param amountOut Amount of `offeredToken` the buyer wants to receive.
     * @param offeredAmount Total `offeredToken` amount in the order (price denominator).
     * @param requestedAmount Total `requestedToken` amount in the order (price numerator).
     * @return Net amount of `requestedToken` owed before fees.
     */
    function getNetPaymentAmount(
        uint256 amountOut,
        uint256 offeredAmount,
        uint256 requestedAmount
    ) public pure returns (uint256) {
        return (amountOut * requestedAmount) / offeredAmount;
    }

    /**
     * @notice Calculates the protocol fee applied on top of the net payment.
     * @dev fee = netPaymentAmount * percentageFee / 10_000. Default rate is 500 (5%).
     * @param netPaymentAmount Base payment amount before fees.
     * @return Fee amount in `requestedToken` units.
     */
    function getFeePaymentAmount(
        uint256 netPaymentAmount
    ) public view returns (uint256) {
        return applyBasisPoints(netPaymentAmount, percentageFee.current);
    }

    /**
     * @notice Calculates the Volume Weighted Average Price (VWAP) of a market.
     * @dev VWAP = sum(amountB) / sum(amountA) across all active orders, scaled by 1e18.
     *      Returns 0 if there are no active orders.
     * @param marketId Market ID to calculate the VWAP for.
     * @return VWAP price scaled by 1e18 (tokenB units per tokenA unit).
     */
    function getVWAP(bytes32 marketId) public view returns (uint256) {
        uint256 totalAvailableA;
        uint256 totalAvailableB;
        uint256 maxSlot = marketInformation[marketId].maxSlot;

        for (uint256 i = 1; i <= maxSlot; i++) {
            Structs.Order storage o = orders[marketId][i];
            if (o.seller != address(0) && o.amountAvailable > 0) {
                totalAvailableA += o.amountAvailable;
                totalAvailableB +=
                    (o.amountAvailable * o.requestedAmount) / o.offeredAmount;
            }
        }
        return
            totalAvailableA == 0
                ? 0
                : (totalAvailableB * 1e18) / totalAvailableA;
    }

    /**
     * @dev Sends a MATE token reward to the executor if it is a registered staker.
     * @param executor Address of the executor to reward.
     * @param multiplier Reward multiplier applied to the base reward amount (2–5).
     */
    function _rewardExecutor(address executor, uint256 multiplier) internal {
        if (core.isAddressStaker(executor)) {
            makeCaPay(
                executor,
                core.getPrincipalTokenAddress(),
                core.getRewardAmount() * multiplier
            );
        }
    }
}
