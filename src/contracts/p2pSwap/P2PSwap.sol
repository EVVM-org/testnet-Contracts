// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    P2PSwapHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/P2PSwapHashUtils.sol";
import {
    P2PSwapStructs as Structs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

import {EvvmService} from "@evvm/testnet-contracts/library/EvvmService.sol";
import {CoreStructs} from "@evvm/testnet-contracts/interfaces/ICore.sol";

import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";

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
    /// @notice Thrown when the caller is not the order seller.
    error NotTheSeller();
    /// @notice Thrown when the referenced order does not exist.
    error OrderDoesNotExist();
    /// @notice Thrown when the payment amount is below the minimum required.
    error InsufficientPayment();

    /// @notice Current admin address with a pending proposal mechanism.
    ProposalStructs.AddressTypeProposal admin;
    /// @notice Fee split percentages in basis points (seller / service / staker).
    Structs.Percentage basisPointsForReward;
    /// @notice Proportional fee rate in basis points applied to fills (500 = 5%).
    ProposalStructs.UintTypeProposal percentageFee;

    /// @notice Stores market metadata indexed by the hash of the token pair.
    mapping(bytes32 marketId => Structs.MarketInformation) marketInformation;
    /// @notice Stores orders indexed by market ID and order slot.
    mapping(bytes32 marketId => mapping(uint256 orderId => Structs.Order)) orders;

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
        basisPointsForReward = Structs.Percentage({
            seller: 5000,
            service: 4000,
            mateStaker: 1000
        });
    }

    /**
     * @notice Creates a new limit order in a trading market.
     * @dev Locks tokenA in Core.sol. The market is identified by the hash of (tokenA, tokenB).
     *      If all slots are occupied, a new slot is allocated; otherwise the first empty slot is reused.
     *      The VWAP of the market is updated after each order.
     * @param user Seller address.
     * @param tokenA Address of the token being sold.
     * @param tokenB Address of the token being bought.
     * @param amountA Amount of tokenA offered.
     * @param amountB Amount of tokenB requested.
     * @param senderExecutor Address of the calling executor (must match msg.sender).
     * @param originExecutor Origin address for signature validation.
     * @param nonce Async nonce for this operation.
     * @param signature Seller's authorization signature.
     * @param priorityFeePay Optional priority fee in tokenA for the executor.
     * @param noncePay Nonce for the Core payment that locks tokenA.
     * @param signaturePay Signature for the Core payment.
     */
    function makeOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForMakeOrder(tokenA, tokenB, amountA, amountB),
            originExecutor,
            nonce,
            true,
            signature
        );

        requestPay(
            user,
            tokenA,
            amountA,
            priorityFeePay,
            originExecutor,
            noncePay,
            true,
            signaturePay
        );

        //we get the market id from the token pair
        bytes32 marketId = getMarketId(tokenA, tokenB);

        uint256 orderId;

        // we start by checking if the market exists, if not we create it
        if (
            marketInformation[marketId].maxSlot ==
            marketInformation[marketId].ordersAvailable
        ) {
            marketInformation[marketId].maxSlot++;
            marketInformation[marketId].ordersAvailable++;
            orderId = marketInformation[marketId].maxSlot;
        } else {
            for (
                uint256 i = 1;
                i <= marketInformation[marketId].maxSlot + 1;
                i++
            ) {
                if (orders[marketId][i].seller == address(0)) {
                    orderId = i;
                    break;
                }
            }
            marketInformation[marketId].ordersAvailable++;
        }

        // we create the order
        orders[marketId][orderId] = Structs.Order({
            seller: user,
            amountA: amountA,
            amountB: amountB
        });

        // we calculate the median price for the market and update it
        marketInformation[marketId].medianPrice = getVWAP(marketId);

        if (core.isAddressStaker(msg.sender) && priorityFeePay > 0)
            makeCaPay(msg.sender, tokenA, priorityFeePay);

        // send some mate token reward to the executor (independent of the priorityFee the user attached)
        _rewardExecutor(msg.sender, priorityFeePay > 0 ? 3 : 2);
    }

    /**
     * @notice Cancels an existing order and refunds locked tokenA to the seller.
     * @dev Only the order owner can cancel. The market slot is recycled for new orders.
     * @param user Order owner address.
     * @param tokenA Token being sold.
     * @param tokenB Token being bought.
     * @param orderId Order slot to cancel.
     * @param senderExecutor Address of the calling service (must match msg.sender).
     * @param originExecutor Origin address for signature validation.
     * @param nonce Async nonce for this operation.
     * @param signature Cancellation authorization signature.
     * @param priorityFeePay Optional priority fee for the executor.
     * @param noncePay Nonce for the priority fee payment.
     * @param signaturePay Signature for the priority fee payment.
     */
    function cancelOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForCancelOrder(tokenA, tokenB, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        bytes32 marketId = getMarketId(tokenA, tokenB);

        // we store the order in memory to save gas
        Structs.Order memory order = orders[marketId][orderId];

        // we check if the order exists and if the user is the seller
        if (order.seller != user) revert NotTheSeller();

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

        // we delete the order
        _clearOrderAndUpdateMarket(marketId, orderId);

        // we calculate the median price for the market and update it
        marketInformation[marketId].medianPrice = getVWAP(marketId);

        makeCaPay(user, tokenA, order.amountA);

        if (core.isAddressStaker(msg.sender) && priorityFeePay > 0)
            makeCaPay(
                msg.sender,
                core.getPrincipalTokenAddress(),
                priorityFeePay
            );

        _rewardExecutor(msg.sender, priorityFeePay > 0 ? 3 : 2);
    }
    
    /**
     * @notice Fills an existing order, paying tokenB to receive tokenA.
     * @dev fee = amountB * percentageFee / 10_000. Overpayment is automatically refunded.
     *      The fee is split among the seller, the protocol, and the executor per basisPointsForReward.
     * @param user Buyer address filling the order.
     * @param tokenA Token being bought by the filler (tokenA of the order).
     * @param tokenB Token being sold by the filler (tokenB of the order).
     * @param orderId Order slot to fill.
     * @param amountOfTokenBToFill Amount of tokenB sent by the buyer (must be >= amountB + fee).
     * @param senderExecutor Address of the calling executor (must match msg.sender).
     * @param originExecutor Origin address for signature validation.
     * @param nonce Async nonce for this operation.
     * @param signature Buyer's authorization signature.
     * @param priorityFeePay Optional priority fee in the principal token for the executor.
     * @param noncePay Nonce for the Core payment.
     * @param signaturePay Signature for the Core payment.
     */
    function dispatchOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        uint256 amountOfTokenBToFill,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bytes calldata signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes calldata signaturePay
    ) external {
        core.validateAndConsumeNonce(
            user,
            senderExecutor,
            Hash.hashDataForDispatchOrder(
                tokenA,
                tokenB,
                orderId
            ),
            originExecutor,
            nonce,
            true,
            signature
        );

        bytes32 market = getMarketId(tokenA, tokenB);
        Structs.Order storage order = orders[market][orderId];

        if (order.seller == address(0)) revert OrderDoesNotExist();

        uint256 fee = applyBasisPoints(order.amountB, percentageFee.current);
        uint256 fullRequired = order.amountB + fee;

        if (amountOfTokenBToFill < fullRequired) revert InsufficientPayment();

        requestPay(
            user,
            tokenB,
            amountOfTokenBToFill,
            priorityFeePay,
            originExecutor,
            noncePay,
            true,
            signaturePay
        );

        bool didRefund = amountOfTokenBToFill > fullRequired;
        if (didRefund)
            makeCaPay(user, tokenB, amountOfTokenBToFill - fullRequired);

        uint256 sellerAmount = order.amountB +
            applyBasisPoints(fee, basisPointsForReward.seller);
        uint256 executorAmount = priorityFeePay +
            applyBasisPoints(fee, basisPointsForReward.mateStaker);

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
        makeDisperseCaPay(toData, tokenB, sellerAmount + executorAmount);

        makeCaPay(user, tokenA, order.amountA);
        _rewardExecutor(msg.sender, didRefund ? 5 : 4);
        _clearOrderAndUpdateMarket(market, orderId);
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
     * @notice Calculates the Volume Weighted Average Price (VWAP) of a market.
     * @dev VWAP = sum(amountB) / sum(amountA) across all active orders, scaled by 1e18.
     *      Returns 0 if there are no active orders.
     * @param marketId Market ID to calculate the VWAP for.
     * @return VWAP price scaled by 1e18 (tokenB units per tokenA unit).
     */
    function getVWAP(bytes32 marketId) public view returns (uint256) {
        uint256 totalA;
        uint256 totalB;
        uint256 maxSlot = marketInformation[marketId].maxSlot;

        for (uint256 i = 1; i <= maxSlot; i++) {
            Structs.Order storage o = orders[marketId][i];
            if (o.seller != address(0)) {
                totalA += o.amountA;
                totalB += o.amountB;
            }
        }
        return totalA == 0 ? 0 : (totalB * 1e18) / totalA;
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

    /**
     * @dev Deletes an order and decrements the active order count for the market.
     * @param marketId Market containing the order.
     * @param orderId Slot ID of the order to clear.
     */
    function _clearOrderAndUpdateMarket(
        bytes32 marketId,
        uint256 orderId
    ) internal {
        orders[marketId][orderId].seller = address(0);
        marketInformation[marketId].ordersAvailable--;
    }
}
