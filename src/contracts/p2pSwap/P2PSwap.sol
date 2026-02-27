// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {
    P2PSwapHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/P2PSwapHashUtils.sol";
import {
    P2PSwapStructs as Structs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {EvvmService} from "@evvm/testnet-contracts/library/EvvmService.sol";
import {CoreStructs} from "@evvm/testnet-contracts/interfaces/ICore.sol";

import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

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
    address owner;
    address owner_proposal;
    uint256 owner_timeToAccept;

    Structs.Percentage rewardPercentage;
    Structs.Percentage rewardPercentage_proposal;
    uint256 rewardPercentage_timeToAcceptNewChange;

    uint256 percentageFee;
    uint256 percentageFee_proposal;
    uint256 percentageFee_timeToAccept;

    uint256 maxLimitFillFixedFee;
    uint256 maxLimitFillFixedFee_proposal;
    uint256 maxLimitFillFixedFee_timeToAccept;

    address tokenToWithdraw;
    uint256 amountToWithdraw;
    address recipientToWithdraw;
    uint256 timeToWithdrawal;

    uint256 marketCount;

    mapping(address tokenA => mapping(address tokenB => uint256 id)) marketId;

    mapping(uint256 id => Structs.MarketInformation info) marketMetadata;

    mapping(uint256 idMarket => mapping(uint256 idOrder => Structs.Order)) ordersInsideMarket;

    mapping(address => uint256) balancesOfContract;

    constructor(
        address _coreAddress,
        address _stakingAddress,
        address _owner
    ) EvvmService(_coreAddress, _stakingAddress) {
        owner = _owner;
        maxLimitFillFixedFee = 0.001 ether;
        percentageFee = 500;
        rewardPercentage = Structs.Percentage({
            seller: 5000,
            service: 4000,
            mateStaker: 1000
        });
    }

    /**
     * @notice Creates a new limit order in a specific trading market.
     * @dev Locks tokenA in Core.sol and opens an order slot.
     *      Markets are automatically created for new token pairs.
     * @param user Seller address.
     * @param tokenA Address of the token being sold.
     * @param tokenB Address of the token being bought.
     * @param amountA Amount of tokenA offered.
     * @param amountB Amount of tokenB requested.
     * @param originExecutor executor address for signature validation.
     * @param nonce Nonce for service execution (async).
     * @param signature Seller's authorization signature.
     * @param priorityFeePay Optional priority fee for the executor.
     * @param noncePay Nonce for the Core payment (locks tokenA).
     * @param signaturePay Signature for the Core payment.
     * @return market The ID of the market.
     * @return orderId The ID of the order within that market.
     */
    function makeOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external returns (uint256 market, uint256 orderId) {
        core.validateAndConsumeNonce(
            user,
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
            noncePay,
            true,
            signaturePay
        );

        market = findMarket(tokenA, tokenB);
        if (market == 0) {
            market = createMarket(tokenA, tokenB);
        }

        if (
            marketMetadata[market].maxSlot ==
            marketMetadata[market].ordersAvailable
        ) {
            marketMetadata[market].maxSlot++;
            marketMetadata[market].ordersAvailable++;
            orderId = marketMetadata[market].maxSlot;
        } else {
            for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
                if (ordersInsideMarket[market][i].seller == address(0)) {
                    orderId = i;
                    break;
                }
            }
            marketMetadata[market].ordersAvailable++;
        }

        ordersInsideMarket[market][orderId] = Structs.Order(
            user,
            amountA,
            amountB
        );

        if (core.isAddressStaker(msg.sender)) {
            if (priorityFeePay > 0) {
                // send the executor the priorityFee
                makeCaPay(msg.sender, tokenA, priorityFeePay);
            }
        }

        // send some mate token reward to the executor (independent of the priorityFee the user attached)
        _rewardExecutor(msg.sender, priorityFeePay > 0 ? 3 : 2);
    }

    /**
     * @notice Cancels existing order and refunds locked tokens
     * @dev Validates ownership, refunds tokenA, deletes order
     *
     * Cancellation Flow:
     * 1. Validates signature via Core.sol
     * 2. Validates user is order owner
     * 3. Processes optional priority fee
     * 4. Refunds locked tokenA to user
     * 5. Deletes order (sets seller to address(0))
     * 6. Rewards staker if applicable
     *
     * Core.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes tokenA, tokenB, orderId
     * - Prevents replay attacks and double cancellation
     *
     * Core.sol Integration:
     * - Refunds tokenA via makeCaPay (order.amountA)
     * - Priority fee via requestPay (if > 0)
     * - Staker reward: 2-3x MATE via _rewardExecutor
     * - makeCaPay handles staker priority fee distribution
     *
     * Security:
     * - Only order owner can cancel
     * - Atomic refund + deletion
     * - Market slot becomes available for reuse
     *
     * @param user Address that owns the order
     * @param tokenA Token A in pair
     * @param tokenB Token B in pair
     * @param orderId Order ID to cancel
     * @param originExecutor Executor address for signature validation
     * @param nonce Nonce for service execution (async)
     * @param signature Signature for cancellation authorization
     * @param priorityFeePay Optional priority fee for staker
     * @param noncePay Nonce for EVVM payment transaction
     * @param signaturePay Signature for EVVM payment
     */
    function cancelOrder(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForCancelOrder(tokenA, tokenB, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        uint256 market = findMarket(tokenA, tokenB);

        _validateOrderOwnership(market, orderId, user);

        if (priorityFeePay > 0) {
            requestPay(
                user,
                core.getPrincipalTokenAddress(),
                0,
                priorityFeePay,
                noncePay,
                true,
                signaturePay
            );
        }

        makeCaPay(user, tokenA, ordersInsideMarket[market][orderId].amountA);

        _clearOrderAndUpdateMarket(market, orderId);

        if (core.isAddressStaker(msg.sender) && priorityFeePay > 0) {
            makeCaPay(
                msg.sender,
                core.getPrincipalTokenAddress(),
                priorityFeePay
            );
        }
        _rewardExecutor(msg.sender, priorityFeePay > 0 ? 3 : 2);
    }

    /**
     * @notice Fills order using proportional fee model
     * @dev Fee = amountB * percentageFee / 10,000
     *
     * Proportional Fee Execution Flow:
     * 1. Validates signature via Core.sol
     * 2. Validates market and order exist
     * 3. Calculates fee: (amountB * percentageFee) / 10,000
     * 4. Validates amountOfTokenBToFill >= amountB + fee
     * 5. Collects tokenB + fee via Evvm.requestPay
     * 6. Handles overpayment refund if any
     * 7. Distributes payments (seller, service, staker)
     * 8. Transfers tokenA to buyer via Evvm.makeCaPay
     * 9. Rewards staker (4-5x MATE)
     * 10. Deletes order
     *
     * Core.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes tokenA, tokenB, orderId
     * - Prevents double filling
     *
     * Core.sol Integration:
     * - Collects tokenB via requestPay (amountB + fee)
     * - Distributes via makeDisperseCaPay:
     *   * Seller: amountB + (fee * seller%)
     *   * Staker: priorityFee + (fee * staker%)
     *   * Service: fee * service% (accumulated)
     * - Transfers tokenA to buyer via makeCaPay
     * - Staker reward: 4-5x MATE via _rewardExecutor
     *
     * Fee Calculation:
     * - Base: amountB (order requirement)
     * - Fee: (amountB * percentageFee) / 10,000
     * - Total: amountB + fee
     * - Example: 5% fee = 500 / 10,000
     *
     * @param user Address filling the order (buyer)
     * @param tokenA Token A in pair
     * @param tokenB Token B in pair
     * @param orderId Order ID to fill
     * @param amountOfTokenBToFill Amount of tokenB buyer is paying (must cover order + fee)
     * @param originExecutor Executor address for signature validation
     * @param nonce Nonce for service execution (async)
     * @param signature Signature for dispatch authorization
     * @param priorityFeePay Optional priority fee for staker
     * @param noncePay Nonce for EVVM payment transaction
     * @param signaturePay Signature for EVVM payment
     */
    function dispatchOrder_fillPropotionalFee(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        uint256 amountOfTokenBToFill,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForDispatchOrder(tokenA, tokenB, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        uint256 market = findMarket(tokenA, tokenB);

        Structs.Order storage order = _validateMarketAndOrder(market, orderId);

        uint256 fee = calculateFillPropotionalFee(order.amountB);
        uint256 requiredAmount = order.amountB + fee;

        if (amountOfTokenBToFill < requiredAmount) {
            revert("Insuficient amountOfTokenToFill");
        }

        requestPay(
            user,
            tokenB,
            amountOfTokenBToFill,
            priorityFeePay,
            noncePay,
            true,
            signaturePay
        );

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        bool didRefund = _handleOverpaymentRefund(
            user,
            tokenB,
            amountOfTokenBToFill,
            requiredAmount
        );

        // distribute payments to seller and executor
        _distributePayments(
            tokenB,
            order.amountB,
            fee,
            order.seller,
            msg.sender,
            priorityFeePay
        );

        // pay user with token A
        makeCaPay(user, tokenA, order.amountA);

        _rewardExecutor(msg.sender, didRefund ? 5 : 4);

        _clearOrderAndUpdateMarket(market, orderId);
    }

    /**
     * @notice Fills order using fixed/capped fee model
     * @dev Fee = min(proportionalFee, maxLimitFillFixedFee)
     * with -10% tolerance
     *
     * Fixed Fee Execution Flow:
     * 1. Validates signature via Core.sol
     * 2. Validates market and order exist
     * 3. Calculates capped fee and 10% tolerance
     * 4. Validates amountOfTokenBToFill >= amountB + fee - 10%
     * 5. Collects tokenB + amount via Evvm.requestPay
     * 6. Calculates final fee based on actual payment
     * 7. Handles overpayment refund if any
     * 8. Distributes payments (seller, service, staker)
     * 9. Transfers tokenA to buyer via Evvm.makeCaPay
     * 10. Rewards staker (4-5x MATE)
     * 11. Deletes order
     *
     * Core.sol Integration:
     * - Validates signature with State.validateAndConsumeNonce
     * - Uses async nonce (isAsyncExec = true)
     * - Hash includes tokenA, tokenB, orderId
     * - Prevents double filling
     *
     * Core.sol Integration:
     * - Collects tokenB via requestPay (variable amount)
     * - Distributes via makeDisperseCaPay:
     *   * Seller: amountB + (finalFee * seller%)
     *   * Staker: priorityFee + (finalFee * staker%)
     *   * Service: finalFee * service% (accumulated)
     * - Transfers tokenA to buyer via makeCaPay
     * - Staker reward: 4-5x MATE via _rewardExecutor
     *
     * Fee Calculation:
     * - Base: amountB (order requirement)
     * - ProportionalFee: (amountB * percentageFee) / 10,000
     * - Fee: min(proportionalFee, maxLimitFillFixedFee)
     * - Tolerance: fee * 10% (fee10)
     * - MinRequired: amountB + fee - fee10
     * - FullRequired: amountB + fee
     * - FinalFee: Based on actual payment amount
     *
     * Tolerance Range:
     * - Accepts payment between [amountB + 90% fee] and
     *   [amountB + 100% fee]
     * - Calculates actual fee from payment received
     * - Enables flexible fee payment for users
     *
     * @param user Address filling the order (buyer)
     * @param tokenA Token A in pair
     * @param tokenB Token B in pair
     * @param orderId Order ID to fill
     * @param amountOfTokenBToFill Amount of tokenB buyer is paying (must cover order + fee)
     * @param originExecutor Executor address for signature validation
     * @param nonce Nonce for service execution (async)
     * @param signature Signature for dispatch authorization
     * @param priorityFeePay Optional priority fee for staker
     * @param noncePay Nonce for EVVM payment transaction
     * @param signaturePay Signature for EVVM payment
     * @param maxFillFixedFee Max fee cap (for testing)
     */
    function dispatchOrder_fillFixedFee(
        address user,
        address tokenA,
        address tokenB,
        uint256 orderId,
        uint256 amountOfTokenBToFill,
        address originExecutor,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFeePay,
        uint256 noncePay,
        bytes memory signaturePay,
        uint256 maxFillFixedFee ///@dev for testing purposes
    ) external {
        core.validateAndConsumeNonce(
            user,
            Hash.hashDataForDispatchOrder(tokenA, tokenB, orderId),
            originExecutor,
            nonce,
            true,
            signature
        );

        uint256 market = findMarket(tokenA, tokenB);

        Structs.Order storage order = _validateMarketAndOrder(market, orderId);

        (uint256 fee, uint256 fee10) = calculateFillFixedFee(
            order.amountB,
            maxFillFixedFee
        );

        uint256 minRequired = order.amountB + fee - fee10;
        uint256 fullRequired = order.amountB + fee;

        if (amountOfTokenBToFill < minRequired) {
            revert("Insuficient amountOfTokenBToFill");
        }

        requestPay(
            user,
            tokenB,
            amountOfTokenBToFill,
            priorityFeePay,
            noncePay,
            true,
            signaturePay
        );

        uint256 finalFee = _calculateFinalFee(
            amountOfTokenBToFill,
            order.amountB,
            fee,
            fee10
        );

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        bool didRefund = _handleOverpaymentRefund(
            user,
            tokenB,
            amountOfTokenBToFill,
            fullRequired
        );

        // distribute payments to seller and executor
        _distributePayments(
            tokenB,
            order.amountB,
            finalFee,
            order.seller,
            msg.sender,
            priorityFeePay
        );

        makeCaPay(user, tokenA, order.amountA);

        _rewardExecutor(msg.sender, didRefund ? 5 : 4);

        _clearOrderAndUpdateMarket(market, orderId);
    }

    function calculateFillPropotionalFee(
        uint256 amount
    ) internal view returns (uint256 fee) {
        ///@dev get the % of the amount
        fee = (amount * percentageFee) / 10_000;
    }

    function calculateFillFixedFee(
        uint256 amount,
        uint256 maxFillFixedFee
    ) internal view returns (uint256 fee, uint256 fee10) {
        if (calculateFillPropotionalFee(amount) > maxFillFixedFee) {
            fee = maxFillFixedFee;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = calculateFillPropotionalFee(amount);
        }
    }

    /**
     * @dev Calculates the final fee for fixed fee dispatch considering tolerance range
     * @param amountPaid Amount paid by user
     * @param orderAmount Base order amount
     * @param fee Full fee amount
     * @param fee10 10% tolerance of fee
     * @return finalFee The calculated final fee
     */
    function _calculateFinalFee(
        uint256 amountPaid,
        uint256 orderAmount,
        uint256 fee,
        uint256 fee10
    ) internal pure returns (uint256 finalFee) {
        uint256 minRequired = orderAmount + fee - fee10;
        uint256 fullRequired = orderAmount + fee;

        if (amountPaid >= minRequired && amountPaid < fullRequired) {
            finalFee = amountPaid - orderAmount;
        } else {
            finalFee = fee;
        }
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    // Internal helper functions to avoid Stack too deep
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢

    /**
     * @dev Validates that a market and order exist and are valid
     * @param market The market ID
     * @param orderId The order ID within the market
     * @return order The order data if valid
     */
    function _validateMarketAndOrder(
        uint256 market,
        uint256 orderId
    ) internal view returns (Structs.Order storage order) {
        if (market == 0) {
            revert("Invalid order");
        }
        order = ordersInsideMarket[market][orderId];
        if (order.seller == address(0)) {
            revert("Invalid order");
        }
    }

    /**
     * @dev Validates that a market exists and the user is the seller of the order
     * @param market The market ID
     * @param orderId The order ID
     * @param user The expected seller address
     */
    function _validateOrderOwnership(
        uint256 market,
        uint256 orderId,
        address user
    ) internal view {
        if (market == 0 || ordersInsideMarket[market][orderId].seller != user) {
            revert("Invalid order");
        }
    }

    /**
     * @dev Rewards the executor (staker) with MATE tokens based on operation complexity
     * @param executor The address of the executor
     * @param multiplier The reward multiplier (2, 3, 4, or 5)
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
     * @dev Clears an order and updates market metadata
     * @param market The market ID
     * @param orderId The order ID to clear
     */
    function _clearOrderAndUpdateMarket(
        uint256 market,
        uint256 orderId
    ) internal {
        ordersInsideMarket[market][orderId].seller = address(0);
        marketMetadata[market].ordersAvailable--;
    }

    /**
     * @dev Handles refund to user if they overpaid
     * @param user The user address to refund
     * @param token The token address
     * @param amountPaid The amount the user paid
     * @param amountRequired The required amount (order amount + fee)
     * @return didRefund Whether a refund was made
     */
    function _handleOverpaymentRefund(
        address user,
        address token,
        uint256 amountPaid,
        uint256 amountRequired
    ) internal returns (bool didRefund) {
        if (amountPaid > amountRequired) {
            makeCaPay(user, token, amountPaid - amountRequired);
            return true;
        }
        return false;
    }

    /**
     * @dev Distributes payment to seller and executor, and accumulates service fee
     * @param token The token address for payment
     * @param orderAmount The base order amount
     * @param fee The fee amount to distribute
     * @param seller The seller address
     * @param executor The executor address
     * @param priorityFee The priority fee for executor
     */
    function _distributePayments(
        address token,
        uint256 orderAmount,
        uint256 fee,
        address seller,
        address executor,
        uint256 priorityFee
    ) internal {
        uint256 sellerAmount = orderAmount +
            ((fee * rewardPercentage.seller) / 10_000);
        uint256 executorAmount = priorityFee +
            ((fee * rewardPercentage.mateStaker) / 10_000);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](2);

        toData[0] = CoreStructs.DisperseCaPayMetadata(sellerAmount, seller);
        toData[1] = CoreStructs.DisperseCaPayMetadata(executorAmount, executor);

        balancesOfContract[token] += (fee * rewardPercentage.service) / 10_000;

        makeDisperseCaPay(toData, token, sellerAmount + executorAmount);
    }

    function createMarket(
        address tokenA,
        address tokenB
    ) internal returns (uint256) {
        marketCount++;
        marketId[tokenA][tokenB] = marketCount;
        marketMetadata[marketCount] = Structs.MarketInformation(
            tokenA,
            tokenB,
            0,
            0
        );
        return marketCount;
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    // Admin tools
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢

    function proposeOwner(address _owner) external {
        if (msg.sender != owner) {
            revert();
        }
        owner_proposal = _owner;
        owner_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposeOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner_proposal = address(0);
    }

    function acceptOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner = owner_proposal;
        owner_proposal = address(0);
    }

    function proposeFillFixedPercentage(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external {
        if (msg.sender != owner) {
            revert();
        }
        if (_seller + _service + _mateStaker != 10_000) {
            revert();
        }
        rewardPercentage_proposal = Structs.Percentage(
            _seller,
            _service,
            _mateStaker
        );
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Structs.Percentage(0, 0, 0);
    }

    function acceptFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    function proposeFillPropotionalPercentage(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external {
        if (msg.sender != owner || _seller + _service + _mateStaker != 10_000) {
            revert();
        }
        rewardPercentage_proposal = Structs.Percentage(
            _seller,
            _service,
            _mateStaker
        );
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Structs.Percentage(0, 0, 0);
    }

    function acceptFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    function proposePercentageFee(uint256 _percentageFee) external {
        if (msg.sender != owner) {
            revert();
        }
        percentageFee_proposal = _percentageFee;
        percentageFee_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposePercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee_proposal = 0;
    }

    function acceptPercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee = percentageFee_proposal;
    }

    function proposeMaxLimitFillFixedFee(
        uint256 _maxLimitFillFixedFee
    ) external {
        if (msg.sender != owner) {
            revert();
        }
        maxLimitFillFixedFee_proposal = _maxLimitFillFixedFee;
        maxLimitFillFixedFee_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposeMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee_proposal = 0;
    }

    function acceptMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee = maxLimitFillFixedFee_proposal;
    }

    function proposeWithdrawal(
        address _tokenToWithdraw,
        uint256 _amountToWithdraw,
        address _to
    ) external {
        if (
            msg.sender != owner ||
            _amountToWithdraw > balancesOfContract[_tokenToWithdraw]
        ) {
            revert();
        }
        tokenToWithdraw = _tokenToWithdraw;
        amountToWithdraw = _amountToWithdraw;
        recipientToWithdraw = _to;
        timeToWithdrawal = block.timestamp + 1 days;
    }

    function rejectProposeWithdrawal() external {
        if (msg.sender != owner || block.timestamp > timeToWithdrawal) {
            revert();
        }
        tokenToWithdraw = address(0);
        amountToWithdraw = 0;
        recipientToWithdraw = address(0);
        timeToWithdrawal = 0;
    }

    function acceptWithdrawal() external {
        if (msg.sender != owner || block.timestamp > timeToWithdrawal) {
            revert();
        }
        makeCaPay(recipientToWithdraw, tokenToWithdraw, amountToWithdraw);
        balancesOfContract[tokenToWithdraw] -= amountToWithdraw;

        tokenToWithdraw = address(0);
        amountToWithdraw = 0;
        recipientToWithdraw = address(0);
        timeToWithdrawal = 0;
    }

    function stake(uint256 amount) external {
        if (
            msg.sender != owner ||
            amount * staking.priceOfStaking() >
            balancesOfContract[0x0000000000000000000000000000000000000001]
        ) revert();

        _makeStakeService(amount);
    }

    function unstake(uint256 amount) external {
        if (msg.sender != owner) revert();

        _makeUnstakeService(amount);
    }

    function addBalance(address _token, uint256 _amount) external {
        if (msg.sender != owner) {
            revert();
        }
        balancesOfContract[_token] += _amount;
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    //getters
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    function getAllMarketOrders(
        uint256 market
    ) public view returns (Structs.OrderForGetter[] memory orders) {
        orders = new Structs.OrderForGetter[](
            marketMetadata[market].maxSlot + 1
        );

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller != address(0)) {
                orders[i - 1] = Structs.OrderForGetter(
                    market,
                    i,
                    ordersInsideMarket[market][i].seller,
                    ordersInsideMarket[market][i].amountA,
                    ordersInsideMarket[market][i].amountB
                );
            }
        }
        return orders;
    }

    function getOrder(
        uint256 market,
        uint256 orderId
    ) public view returns (Structs.Order memory order) {
        order = ordersInsideMarket[market][orderId];
        return order;
    }

    function getMyOrdersInSpecificMarket(
        address user,
        uint256 market
    ) public view returns (Structs.OrderForGetter[] memory orders) {
        orders = new Structs.OrderForGetter[](
            marketMetadata[market].maxSlot + 1
        );

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller == user) {
                orders[i - 1] = Structs.OrderForGetter(
                    market,
                    i,
                    ordersInsideMarket[market][i].seller,
                    ordersInsideMarket[market][i].amountA,
                    ordersInsideMarket[market][i].amountB
                );
            }
        }
        return orders;
    }

    function findMarket(
        address tokenA,
        address tokenB
    ) public view returns (uint256) {
        return marketId[tokenA][tokenB];
    }

    function getMarketMetadata(
        uint256 market
    ) public view returns (Structs.MarketInformation memory) {
        return marketMetadata[market];
    }

    function getAllMarketsMetadata()
        public
        view
        returns (Structs.MarketInformation[] memory)
    {
        Structs.MarketInformation[]
            memory markets = new Structs.MarketInformation[](marketCount + 1);
        for (uint256 i = 1; i <= marketCount; i++) {
            markets[i - 1] = marketMetadata[i];
        }
        return markets;
    }

    function getBalanceOfContract(
        address token
    ) external view returns (uint256) {
        return balancesOfContract[token];
    }

    function getOwnerProposal() external view returns (address) {
        return owner_proposal;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getOwnerTimeToAccept() external view returns (uint256) {
        return owner_timeToAccept;
    }

    function getRewardPercentageProposal()
        external
        view
        returns (Structs.Percentage memory)
    {
        return rewardPercentage_proposal;
    }

    function getRewardPercentage()
        external
        view
        returns (Structs.Percentage memory)
    {
        return rewardPercentage;
    }

    function getProposalPercentageFee() external view returns (uint256) {
        return percentageFee_proposal;
    }

    function getPercentageFee() external view returns (uint256) {
        return percentageFee;
    }

    function getMaxLimitFillFixedFeeProposal() external view returns (uint256) {
        return maxLimitFillFixedFee_proposal;
    }

    function getMaxLimitFillFixedFee() external view returns (uint256) {
        return maxLimitFillFixedFee;
    }

    function getProposedWithdrawal()
        external
        view
        returns (address, uint256, address, uint256)
    {
        return (
            tokenToWithdraw,
            amountToWithdraw,
            recipientToWithdraw,
            timeToWithdrawal
        );
    }
}
