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
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    CoreStorage
} from "@evvm/testnet-contracts/contracts/core/lib/CoreStorage.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";

contract unitTestRevert_P2PSwap_dispatchOrder_fillPropotionalFee is
    Test,
    Constants
{
    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
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
        uint256 noncePay
    ) private returns (uint256 market, uint256 orderId) {
        // build p2p signature (seller authorizes order)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                amountA,
                amountB
            )
        );
        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // payment signature to lock amountA
        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(executor.Address);
        (market, orderId) = p2pSwap.makeOrder(
            user.Address,
            tokenA,
            tokenB,
            amountA,
            amountB,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_revert__dispatchOrder_fillPropotionalFee_invalidSignature()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;
        

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

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
            noncePay
        );

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenA, // tokenA repeated, invalid signature here
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // compute amount to fill
        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );

        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // make sure the order is there
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillPropotionalFee_invalidNonce()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

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
            noncePay
        );

        // use the current nonceP2PSwap
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
            noncePay
        );
        // now, nonceP2PSwap has been used, must generate an error when trying to use it again
        noncePay++;

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // compute amount to fill
        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );

        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // make sure the order is there
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillPropotionalFee_invalidOrder()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                1 // nonexistent orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // compute amount to fill
        uint256 amountToFill = amountB + fee;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountToFill,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );

        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            1,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        // 4. assertions
        // order = p2pSwap.getOrder(1, 1);
        // assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        // assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        // assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        // assertEq(
        //     core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
        //     amountB + fee
        // );
    }

    function test__unit_revert__dispatchOrder_fillPropotionalFee_insufficientAmount()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;
        

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

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
            noncePay
        );
        // nonceP2PSwap = 56565;
        // noncePay++;

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // compute full amount expected (including fee)
        uint256 amountToFill = amountB + fee;

        // intentionally sign pay for insufficient amount (just amountB)
        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountB,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );

        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // make sure the order is there
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }

    function test__unit_revert__dispatchOrder_fillPropotionalFee_invalidPay()
        external
    {
        // 1. define params
        uint256 nonceP2PSwap = 14569;
        address tokenA = ETHER_ADDRESS;
        address tokenB = PRINCIPAL_TOKEN_ADDRESS;
        uint256 amountA = 0.001 ether;
        uint256 amountB = 0.01 ether;
        uint256 priorityFee = 0;
        uint256 noncePay = 0;
        

        uint256 fee = (amountB * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, amountA);
        addBalance(COMMON_USER_NO_STAKER_2.Address, tokenB, amountB + fee);
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            50000000000000000000
        );

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
            noncePay
        );

        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
                nonceP2PSwap,
                tokenA,
                tokenB,
                orderId
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // compute amount to fill
        uint256 amountToFill = amountB + fee;

        // sign pay with wrong amount
        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenB,
                amountB,
                priorityFee,
                address(p2pSwap),
                noncePay,
                true
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(v, r, s);

        // make sure the order is there
        P2PSwapStructs.Order memory order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);

        // dispatch order with amountB
        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        p2pSwap.dispatchOrder_fillPropotionalFee(
            COMMON_USER_NO_STAKER_2.Address,
            tokenA,
            tokenB,
            orderId,
            amountToFill,
            address(0),
            nonceP2PSwap,
            signatureP2P,
            priorityFee,
            noncePay,
            signaturePay
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, COMMON_USER_NO_STAKER_1.Address);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB), 0);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB),
            amountB + fee
        );
    }
}
