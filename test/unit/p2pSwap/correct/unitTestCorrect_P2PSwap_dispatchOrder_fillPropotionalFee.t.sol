// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**                                                                                                        
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄ 
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██   
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██   
                                                    
                                                    
                                                    
 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄          
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██            
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██                                                    
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

contract unitTestCorrect_P2PSwap_dispatchOrder_fillPropotionalFee is
    Test,
    Constants
{
    

    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    /// @notice Creates an order for testing purposes
    function createOrder(
        AccountData memory executor,
        AccountData memory user,
        uint256 nonceP2PSwap,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlag
    ) private returns (uint256 market, uint256 orderId) {
        P2PSwapStructs.MetadataMakeOrder memory orderData = P2PSwapStructs
            .MetadataMakeOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                amountA: amountA,
                amountB: amountB
            });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                amountA,
                amountB
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(executor.Address);
        (market, orderId) = p2pSwap.makeOrder(
            user.Address,
            orderData,
            signatureP2P,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_correct__dispatchOrder_fillPropotionalFee_paySync_noPriorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 nonceEVVM = 0;
        bool priorityFlag = false;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            priorityFee,
            nonceEVVM,
            priorityFlag
        );
        // nonceP2PSwap = 56565;
        // nonceEVVM++;

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // 3.2 crete evvm signature
        P2PSwap.MetadataDispatchOrder memory metadata = P2PSwapStructs
            .MetadataDispatchOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: amountB + fee,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // make sure the order is there
        P2PSwap.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        // at this point, order should be dispatched, which means:
        // order has beed deleted
        // user1 (seller)
        // --amountA
        // ++amountB
        // ++50% of the fee
        //
        // user2 (buyer)
        // --amountB + fee
        // ++amountA
        //
        // p2pswap contract
        // ++40% of the fee
        //
        // executor
        // ++10% of the fee as reward
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * 4000) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = (fee * 1000) / 10_000;
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
            executorAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillPropotionalFee_paySync_priorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0.0001 ether;
        uint256 nonceEVVM = 0;
        bool priorityFlag = false;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            amountB + fee + priorityFee
        );
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            0, // priorityFee is 0 for createOrder
            nonceEVVM,
            priorityFlag
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // 3.2 crete evvm signature
        P2PSwap.MetadataDispatchOrder memory metadata = P2PSwapStructs
            .MetadataDispatchOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: amountB + fee,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // make sure the order is there
        P2PSwap.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * 4000) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = (fee * 1000) / 10_000;
        executorAmount += priorityFee;
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
            executorAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillPropotionalFee_payAsync_noPriorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 nonceEVVM = 1233;
        bool priorityFlag = true;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            priorityFee,
            nonceEVVM,
            priorityFlag
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // 3.2 crete evvm signature
        P2PSwap.MetadataDispatchOrder memory metadata = P2PSwapStructs
            .MetadataDispatchOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: amountB + fee,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // make sure the order is there
        P2PSwap.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        // at this point, order should be dispatched, which means:
        // order has beed deleted
        // user1 (seller)
        // --amountA
        // ++amountB
        // ++50% of the fee
        //
        // user2 (buyer)
        // --amountB + fee
        // ++amountA
        //
        // p2pswap contract
        // ++40% of the fee
        //
        // executor
        // ++10% of the fee as reward
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * 4000) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = (fee * 1000) / 10_000;
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
            executorAmount
        );
    }

    function test__unit_correct__dispatchOrder_fillPropotionalFee_payAsync_priorityFee()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0.0001 ether;
        uint256 nonceEVVM = 949234;
        bool priorityFlag = true;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            amountB + fee + priorityFee
        );
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            nonceP2PSwap,
            tokenA,
            tokenB,
            amountA,
            amountB,
            0, // priorityFee is 0 for createOrder
            nonceEVVM,
            priorityFlag
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // 3.2 crete evvm signature
        P2PSwap.MetadataDispatchOrder memory metadata = P2PSwapStructs
            .MetadataDispatchOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: amountB + fee,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // make sure the order is there
        P2PSwap.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            amountA
        );
        uint256 sellerAmount = amountB + ((fee * 5000) / 10_000);
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * 4000) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = (fee * 1000) / 10_000;
        executorAmount += priorityFee;
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
            executorAmount
        );
    }
}
