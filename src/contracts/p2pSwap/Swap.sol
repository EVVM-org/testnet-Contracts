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
    error NotTheSeller();
    error OrderDoesNotExist();
    error InsufficientPayment();

    ProposalStructs.AddressTypeProposal admin;
    Structs.Percentage basisPointsForReward;
    ProposalStructs.UintTypeProposal maxLimitFillFixedFee;
    ProposalStructs.UintTypeProposal percentageFee;

    mapping(bytes32 marketId => Structs.MarketInformation) marketInformation; // marketId => MarketInformation
    mapping(bytes32 marketId => mapping(uint256 orderId => Structs.Order)) orders; // marketId => orderId => Order

    constructor(
        address _coreAddress,
        address _stakingAddress,
        address _admin
    ) EvvmService(_coreAddress, _stakingAddress) {
        admin.current = _admin;
        maxLimitFillFixedFee.current = 0.001 ether;
        percentageFee.current = 500;
        basisPointsForReward = Structs.Percentage({
            seller: 5000,
            service: 4000,
            mateStaker: 1000
        });
    }

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

    function dispatchOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        uint256 amountOfTokenBToFill,
        bool useFixedFee,
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
            Hash.hashDataForDispatchOrder(tokenA, tokenB, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        bytes32 market = getMarketId(tokenA, tokenB);
        Structs.Order storage order = orders[market][orderId];

        if (order.seller == address(0)) revert OrderDoesNotExist();

        uint256 fee;
        uint256 fee10; // queda en 0 si es proporcional

        if (useFixedFee) {
            uint256 proportionalFee = applyBasisPoints(
                order.amountB,
                percentageFee.current
            );
            fee = proportionalFee > maxLimitFillFixedFee.current
                ? maxLimitFillFixedFee.current
                : proportionalFee;
            fee10 = applyBasisPoints(fee, 1000);
        } else {
            fee = applyBasisPoints(order.amountB, percentageFee.current);
        }

        // con fee10=0: minRequired == fullRequired → sin ventana de tolerancia
        uint256 minRequired = order.amountB + fee - fee10;
        uint256 fullRequired = order.amountB + fee;

        if (amountOfTokenBToFill < minRequired) revert InsufficientPayment();

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

        // _calculateFinalFee con fee10=0 siempre retorna fee (proporcional)
        uint256 finalFee = (amountOfTokenBToFill >= minRequired &&
            amountOfTokenBToFill < fullRequired)
            ? amountOfTokenBToFill - order.amountB
            : fee;

        bool didRefund = amountOfTokenBToFill > fullRequired;
        if (didRefund)
            makeCaPay(user, tokenB, amountOfTokenBToFill - fullRequired);

        uint256 sellerAmount = order.amountB +
            applyBasisPoints(finalFee, basisPointsForReward.seller);
        uint256 executorAmount = priorityFeePay +
            applyBasisPoints(finalFee, basisPointsForReward.mateStaker);

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

    function getMarketId(
        address tokenA,
        address tokenB
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    function applyBasisPoints(
        uint256 amount,
        uint256 basisPoints
    ) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

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

    function _rewardExecutor(address executor, uint256 multiplier) internal {
        if (core.isAddressStaker(executor)) {
            makeCaPay(
                executor,
                core.getPrincipalTokenAddress(),
                core.getRewardAmount() * multiplier
            );
        }
    }

    function _clearOrderAndUpdateMarket(
        bytes32 marketId,
        uint256 orderId
    ) internal {
        orders[marketId][orderId].seller = address(0);
        marketInformation[marketId].ordersAvailable--;
    }
}
