// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
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

 * @title P2P Swap Service
 * @author Mate labs  
 * @notice Peer-to-peer decentralized exchange for token trading within the EVVM ecosystem
 * @dev Implements order book-style trading with dynamic market creation, fee distribution,
 *      and integration with EVVM's staking and payment systems. Supports both proportional
 *      and fixed fee models with time-delayed governance for parameter updates.
 * 
 * Key Features:
 * - Dynamic market creation for any token pair
 * - Order management (create, cancel, execute)
 * - Configurable fee structure with multi-party distribution
 * - Service staking capabilities via StakingServiceHooks inheritance
 * - ERC-191 signature verification for all operations
 * - Time-delayed administrative governance
 * 
 * Fee Distribution:
 * - Seller: 50% (configurable)
 * - Service: 40% (configurable) 
 * - Staker Rewards: 10% (configurable)
 */

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    SignatureUtils
} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/SignatureUtils.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {EvvmService} from "@evvm/testnet-contracts/library/EvvmService.sol";

contract P2PSwap is EvvmService, P2PSwapStructs {
    address owner;
    address owner_proposal;
    uint256 owner_timeToAccept;

    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;
    address constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

    Percentage rewardPercentage;
    Percentage rewardPercentage_proposal;
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

    mapping(uint256 id => MarketInformation info) marketMetadata;

    mapping(uint256 idMarket => mapping(uint256 idOrder => Order)) ordersInsideMarket;

    mapping(address => uint256) balancesOfContract;

    constructor(
        address _evvmAddress,
        address _stakingAddress,
        address _owner
    ) EvvmService(_evvmAddress, _stakingAddress) {
        owner = _owner;
        maxLimitFillFixedFee = 0.001 ether;
        percentageFee = 500;
        rewardPercentage = Percentage({
            seller: 5000,
            service: 4000,
            mateStaker: 1000
        });
    }

    function makeOrder(
        address user,
        MetadataMakeOrder memory metadata,
        bytes memory signature,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external returns (uint256 market, uint256 orderId) {
        if (
            !SignatureUtils.verifyMessageSignedForMakeOrder(
                evvm.getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.amountA,
                metadata.amountB,
                signature
            )
        ) {
            revert("Invalid signature");
        }

        verifyAsyncNonce(user, metadata.nonce);

        requestPay(
            user,
            metadata.tokenA,
            metadata.amountA,
            _priorityFee_Evvm,
            _nonce_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        market = findMarket(metadata.tokenA, metadata.tokenB);
        if (market == 0) {
            market = createMarket(metadata.tokenA, metadata.tokenB);
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

        ordersInsideMarket[market][orderId] = Order(
            user,
            metadata.amountA,
            metadata.amountB
        );

        if (evvm.isAddressStaker(msg.sender)) {
            if (_priorityFee_Evvm > 0) {
                // send the executor the priorityFee
                makeCaPay(msg.sender, metadata.tokenA, _priorityFee_Evvm);
            }
        }

        // send some mate token reward to the executor (independent of the priorityFee the user attached)
        _rewardExecutor(msg.sender, _priorityFee_Evvm > 0 ? 3 : 2);

        markAsyncNonceAsUsed(user, metadata.nonce);
    }

    function cancelOrder(
        address user,
        MetadataCancelOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForCancelOrder(
                evvm.getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        verifyAsyncNonce(user, metadata.nonce);

        _validateOrderOwnership(market, metadata.orderId, user);

        if (_priorityFee_Evvm > 0) {
            requestPay(
                user,
                MATE_TOKEN_ADDRESS,
                0,
                _priorityFee_Evvm,
                _nonce_Evvm,
                _priority_Evvm,
                _signature_Evvm
            );
        }

        makeCaPay(
            user,
            metadata.tokenA,
            ordersInsideMarket[market][metadata.orderId].amountA
        );

        _clearOrderAndUpdateMarket(market, metadata.orderId);

        if (evvm.isAddressStaker(msg.sender) && _priorityFee_Evvm > 0) {
            makeCaPay(msg.sender, MATE_TOKEN_ADDRESS, _priorityFee_Evvm);
        }
        _rewardExecutor(msg.sender, _priorityFee_Evvm > 0 ? 3 : 2);

        markAsyncNonceAsUsed(user, metadata.nonce);
    }

    function dispatchOrder_fillPropotionalFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        verifyAsyncNonce(user, metadata.nonce);

        Order storage order = _validateMarketAndOrder(market, metadata.orderId);

        uint256 fee = calculateFillPropotionalFee(order.amountB);
        uint256 requiredAmount = order.amountB + fee;

        if (metadata.amountOfTokenBToFill < requiredAmount) {
            revert("Insuficient amountOfTokenToFill");
        }

        requestPay(
            user,
            metadata.tokenB,
            metadata.amountOfTokenBToFill,
            _priorityFee_Evvm,
            _nonce_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        bool didRefund = _handleOverpaymentRefund(
            user,
            metadata.tokenB,
            metadata.amountOfTokenBToFill,
            requiredAmount
        );

        // distribute payments to seller and executor
        _distributePayments(
            metadata.tokenB,
            order.amountB,
            fee,
            order.seller,
            msg.sender,
            _priorityFee_Evvm
        );

        // pay user with token A
        makeCaPay(user, metadata.tokenA, order.amountA);

        _rewardExecutor(msg.sender, didRefund ? 5 : 4);

        _clearOrderAndUpdateMarket(market, metadata.orderId);
        markAsyncNonceAsUsed(user, metadata.nonce);
    }

    function dispatchOrder_fillFixedFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm,
        uint256 maxFillFixedFee ///@dev for testing purposes
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        verifyAsyncNonce(user, metadata.nonce);

        Order storage order = _validateMarketAndOrder(market, metadata.orderId);

        (uint256 fee, uint256 fee10) = calculateFillFixedFee(
            order.amountB,
            maxFillFixedFee
        );

        uint256 minRequired = order.amountB + fee - fee10;
        uint256 fullRequired = order.amountB + fee;

        if (metadata.amountOfTokenBToFill < minRequired) {
            revert("Insuficient amountOfTokenBToFill");
        }

        requestPay(
            user,
            metadata.tokenB,
            metadata.amountOfTokenBToFill,
            _priorityFee_Evvm,
            _nonce_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        uint256 finalFee = _calculateFinalFee(
            metadata.amountOfTokenBToFill,
            order.amountB,
            fee,
            fee10
        );

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        bool didRefund = _handleOverpaymentRefund(
            user,
            metadata.tokenB,
            metadata.amountOfTokenBToFill,
            fullRequired
        );

        // distribute payments to seller and executor
        _distributePayments(
            metadata.tokenB,
            order.amountB,
            finalFee,
            order.seller,
            msg.sender,
            _priorityFee_Evvm
        );

        makeCaPay(user, metadata.tokenA, order.amountA);

        _rewardExecutor(msg.sender, didRefund ? 5 : 4);

        _clearOrderAndUpdateMarket(market, metadata.orderId);
        markAsyncNonceAsUsed(user, metadata.nonce);
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
    ) internal view returns (Order storage order) {
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
        if (evvm.isAddressStaker(executor)) {
            makeCaPay(
                executor,
                MATE_TOKEN_ADDRESS,
                evvm.getRewardAmount() * multiplier
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

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata(sellerAmount, seller);
        toData[1] = EvvmStructs.DisperseCaPayMetadata(executorAmount, executor);

        balancesOfContract[token] += (fee * rewardPercentage.service) / 10_000;

        makeDisperseCaPay(toData, token, sellerAmount + executorAmount);
    }

    function createMarket(
        address tokenA,
        address tokenB
    ) internal returns (uint256) {
        marketCount++;
        marketId[tokenA][tokenB] = marketCount;
        marketMetadata[marketCount] = MarketInformation(tokenA, tokenB, 0, 0);
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
        rewardPercentage_proposal = Percentage(_seller, _service, _mateStaker);
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
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
        rewardPercentage_proposal = Percentage(_seller, _service, _mateStaker);
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
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
    ) public view returns (OrderForGetter[] memory orders) {
        orders = new OrderForGetter[](marketMetadata[market].maxSlot + 1);

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller != address(0)) {
                orders[i - 1] = OrderForGetter(
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
    ) public view returns (Order memory order) {
        order = ordersInsideMarket[market][orderId];
        return order;
    }

    function getMyOrdersInSpecificMarket(
        address user,
        uint256 market
    ) public view returns (OrderForGetter[] memory orders) {
        orders = new OrderForGetter[](marketMetadata[market].maxSlot + 1);

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller == user) {
                orders[i - 1] = OrderForGetter(
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
    ) public view returns (MarketInformation memory) {
        return marketMetadata[market];
    }

    function getAllMarketsMetadata()
        public
        view
        returns (MarketInformation[] memory)
    {
        MarketInformation[] memory markets = new MarketInformation[](
            marketCount + 1
        );
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
        returns (Percentage memory)
    {
        return rewardPercentage_proposal;
    }

    function getRewardPercentage() external view returns (Percentage memory) {
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
