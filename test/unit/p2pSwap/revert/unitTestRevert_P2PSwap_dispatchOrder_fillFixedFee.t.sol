// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   ___/ __ \ /  ___\   __\
|    |  |   |  |  ||  |    |  | \  ___/ \___ \ |  |  
|______/|___|  |__||__|    |__|  \___  /____  >|__|  
             \/                      \/     \/       
                                  __                 
_______  _______  __ ____________/  |_               
\_  __ _/ __ \  \/ _/ __ \_  __ \   __\              
 |  | \\  ___/\   /\  ___/|  | \/|  |                
 |__|   \___  >\_/  \___  |__|   |__|                
            \/          \/                                                                                 
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

contract unitTestRevert_P2PSwap_dispatchOrder_fillFixedFee is Test, Constants {
    

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
        uint256 nonceEVVM
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
                address(p2pSwap),
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
                address(evvm),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                true
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
            signatureEVVM
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_revert__dispatchOrder_fillFixedFee_invalidSignature()
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
        bool isAsyncExec = false;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

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
            nonceEVVM
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
                address(p2pSwap),
                nonceP2PSwap,
                tokenA,
                tokenA, // tokenA repeated, invalid signature here
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
                address(evvm),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                true
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
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillFixedFee_invalidNonce()
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
        bool isAsyncExec = false;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

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
            nonceEVVM
        );

        // use nonceP2PSwap
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB);
        createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_2,
            nonceP2PSwap,
            tokenB,
            tokenA,
            amountB,
            amountA,
            priorityFee,
            nonceEVVM
        );
        // now, nonceP2PSwap has been used, must generate an error when trying to use it again
        nonceEVVM++;

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                address(p2pSwap),
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
                address(evvm),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                true
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
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillFixedFee_invalidOrder()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        // uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 nonceEVVM = 0;
        bool isAsyncExec = false;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                address(p2pSwap),
                nonceP2PSwap,
                tokenA,
                tokenB,
                1 // invalid order
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
                orderId: 1,
                amountOfTokenBToFill: amountB + fee,
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                true
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();
    }

    function test__unit_revert__dispatchOrder_fillFixedFee_insufficientAmount()
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
        bool isAsyncExec = false;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

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
            nonceEVVM
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
                address(p2pSwap),
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
                amountOfTokenBToFill: amountB, // should be amountB + fee
                signature: signatureP2P
            });

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                address(p2pSwap),
                "",
                tokenB,
                metadata.amountOfTokenBToFill,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                true
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
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillFixedFee_invalidPay()
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
        bool isAsyncExec = false;

        uint256 proportionalFee = (amountB * 500) / 10_000;
        uint256 _amountOut = 0.001 ether; // greater than proportionalFee
        uint256 fee;
        uint256 fee10;

        if (proportionalFee > _amountOut) {
            fee = _amountOut;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = proportionalFee;
            fee10 = 0;
        }

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
            nonceEVVM
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
                address(p2pSwap),
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
                address(evvm),
                address(p2pSwap),
                "",
                tokenB,
                amountB, // should be metadata.amountOfTokenBToFill,
                priorityFee,
                address(p2pSwap),
                nonceEVVM,
                isAsyncExec
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
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }
}
