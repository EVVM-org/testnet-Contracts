// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";

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
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
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

contract fuzzTest_P2PSwap_dispatchOrder is Test, Constants {


    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;



    function addBalance(address user, address token, uint256 amount) private {
        if (amount == 0) return;
        evvm.addBalance(user, token, amount);
    }

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
        bool isAsyncExec
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
                isAsyncExec
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
            isAsyncExec,
            signatureEVVM
        );
        vm.stopPrank();

        return (market, orderId);
    }

    struct DispatchOrderFuzzTestInput {
        bool hasPriorityFee;
        bool isAsync;
        uint16 amountA;
        uint16 amountB;
        uint16 priorityFee;
        uint16 nonceEVVM;
        uint16 nonceP2PSwap;
        bool tokenScenario;
    }

    function test__fuzz__dispatchOrder_fillPropotionalFee(
        DispatchOrderFuzzTestInput memory input
    ) external {
        vm.assume(input.priorityFee > 0);
        vm.assume(input.amountA > 0 && input.amountB > 0);
        vm.assume(input.nonceEVVM != input.nonceP2PSwap);

        // 1. define params
        address tokenA = input.tokenScenario
            ? ETHER_ADDRESS
            : PRINCIPAL_TOKEN_ADDRESS;
        address tokenB = input.tokenScenario
            ? PRINCIPAL_TOKEN_ADDRESS
            : ETHER_ADDRESS;

        uint256 priorityFee = input.hasPriorityFee ? input.priorityFee : 0;
        uint256 nonceEVVM = input.isAsync ? input.nonceEVVM : 0;

        uint256 fee = (uint256(input.amountB) * 500) / 10_000;

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, input.amountA);
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            input.amountB + fee + priorityFee
        );
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            input.nonceP2PSwap,
            tokenA,
            tokenB,
            input.amountA,
            input.amountB,
            0, // priorityFee is 0 for createOrder
            nonceEVVM,
            input.isAsync
        );
        input.nonceP2PSwap = 43242;

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                address(p2pSwap),
                input.nonceP2PSwap,
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
                nonce: input.nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: input.amountB + fee,
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
                input.isAsync
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
            input.isAsync,
            signatureEVVM
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            input.amountA
        );
        P2PSwap.Percentage memory rewards = p2pSwap.getRewardPercentage();

        uint256 sellerAmount = input.amountB +
            ((fee * rewards.seller) / 10_000);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * 4000) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = 0;

        if (tokenB == PRINCIPAL_TOKEN_ADDRESS) {
            executorAmount += (fee * 1000) / 10_000;
            executorAmount += priorityFee;
        }
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            executorAmount
        );
    }

    function test__fuzz__dispatchOrder_fillFixedFee(
        DispatchOrderFuzzTestInput memory input
    ) external {
        vm.assume(input.priorityFee > 0);
        vm.assume(input.amountA > 0 && input.amountB > 0);
        vm.assume(input.nonceEVVM != input.nonceP2PSwap);

        // 1. define params
        address tokenA = input.tokenScenario
            ? ETHER_ADDRESS
            : PRINCIPAL_TOKEN_ADDRESS;
        address tokenB = input.tokenScenario
            ? PRINCIPAL_TOKEN_ADDRESS
            : ETHER_ADDRESS;

        uint256 priorityFee = input.hasPriorityFee ? input.priorityFee : 0;
        uint256 nonceEVVM = input.isAsync ? input.nonceEVVM : 0;

        uint256 proportionalFee = (uint256(input.amountB) * 500) / 10_000;
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

        addBalance(COMMON_USER_NO_STAKER_1.Address, tokenA, input.amountA);
        addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            tokenB,
            input.amountB + fee + priorityFee
        );
        addBalance(address(p2pSwap), PRINCIPAL_TOKEN_ADDRESS, 50000000000000000000);

        // 2. create an order
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            input.nonceP2PSwap,
            tokenA,
            tokenB,
            input.amountA,
            input.amountB,
            0, // priorityFee is 0 for createOrder
            nonceEVVM,
            input.isAsync
        );
        input.nonceP2PSwap = 43242;

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);

        // 3. dispatch that order
        // 3.1 create p2p signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispatchOrder(
                evvm.getEvvmID(),
                address(p2pSwap),
                input.nonceP2PSwap,
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
                nonce: input.nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                amountOfTokenBToFill: input.amountB + fee,
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
                input.isAsync
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
        p2pSwap.dispatchOrder_fillFixedFee(
            COMMON_USER_NO_STAKER_2.Address,
            metadata,
            priorityFee,
            nonceEVVM,
            input.isAsync,
            signatureEVVM,
            _amountOut
        );
        vm.stopPrank();

        // 4. assertions
        order = p2pSwap.getOrder(market, orderId);
        assertEq(order.seller, address(0));
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenA),
            input.amountA
        );
        P2PSwap.Percentage memory rewards = p2pSwap.getRewardPercentage();

        uint256 sellerAmount = input.amountB +
            ((fee * rewards.seller) / 10_000);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenB),
            sellerAmount
        );

        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA), 0);
        assertEq(evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, tokenB), 0);

        uint256 serviceFee = (fee * rewards.service) / 10_000;
        assertEq(p2pSwap.getBalanceOfContract(tokenB), serviceFee);

        uint256 executorAmount = 0;

        if (tokenB == PRINCIPAL_TOKEN_ADDRESS) {
            executorAmount += (fee * 1000) / 10_000;
            executorAmount += priorityFee;
        }
        executorAmount += 2 * evvm.getRewardAmount(); // from makeOrder
        executorAmount += 4 * evvm.getRewardAmount(); // from dispatchOrder

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            executorAmount
        );
    }
}
