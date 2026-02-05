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

contract fuzzTest_P2PSwap_cancelOrder is Test, Constants {
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
                isAsyncExec,
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
            isAsyncExec,
            signatureEVVM
        );
        vm.stopPrank();

        return (market, orderId);
    }

    struct CancelOrderFuzzTestInput {
        bool hasPriorityFee;
        bool isAsync;
        uint16 amountA;
        uint16 amountB;
        uint16 priorityFee;
        uint16 nonceEVVM;
        uint16 nonceP2PSwap;
        bool tokenScenario;
    }

    function test__fuzz__cancelOrder(
        CancelOrderFuzzTestInput memory input
    ) external {
        // assumptions
        vm.assume(input.priorityFee > 0);
        vm.assume(input.amountA > 0 && input.amountB > 0);

        // Form inputs
        // alternate tokens
        address tokenA = input.tokenScenario
            ? ETHER_ADDRESS
            : PRINCIPAL_TOKEN_ADDRESS;
        address tokenB = input.tokenScenario
            ? PRINCIPAL_TOKEN_ADDRESS
            : ETHER_ADDRESS;

        uint256 priorityFee = input.hasPriorityFee ? input.priorityFee : 0;
        uint256 nonceEVVM = input.isAsync ? input.nonceEVVM : 0;

        uint256 rewardAmountMateToken = priorityFee > 0
            ? evvm.getRewardAmount() * 3
            : evvm.getRewardAmount() * 2;

        uint256 rewardAmountMateTokenCancel = priorityFee > 0
            ? (evvm.getRewardAmount() * 3) + priorityFee
            : (evvm.getRewardAmount() * 2);

        // mate token
        uint256 initialContractBalance = 50000000000000000000;

        // fund account
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            priorityFee
        );
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            tokenA,
            input.amountA + priorityFee
        );
        // fund contract for reward distribution
        addBalance(
            address(p2pSwap),
            PRINCIPAL_TOKEN_ADDRESS,
            initialContractBalance
        );

        // create the order to be cancelled
        // no priorityFee here
        (uint256 market, uint256 orderId) = createOrder(
            COMMON_USER_STAKER,
            COMMON_USER_NO_STAKER_1,
            input.nonceP2PSwap,
            tokenA,
            tokenB,
            input.amountA,
            input.amountB,
            priorityFee,
            nonceEVVM,
            input.isAsync
        );
        // update nonces
        uint256 nextNonceEvvm = uint256(nonceEVVM)+1;
        uint256 nextNonceP2PSwap = uint256(input.nonceP2PSwap)+1;

        // create signatures
        // p2pswap
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForCancelOrder(
                evvm.getEvvmID(),
                nextNonceP2PSwap,
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

        P2PSwapStructs.MetadataCancelOrder memory metadata = P2PSwapStructs
            .MetadataCancelOrder({
                nonce: nextNonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                orderId: orderId,
                signature: signatureP2P
            });

        // pay
        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFee,
                nextNonceEvvm,
                input.isAsync,
                address(p2pSwap)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // execute tx
        vm.startPrank(COMMON_USER_STAKER.Address);
        p2pSwap.cancelOrder(
            COMMON_USER_NO_STAKER_1.Address,
            metadata,
            priorityFee,
            nextNonceEvvm,
            input.isAsync,
            signatureEVVM
        );
        vm.stopPrank();

        P2PSwap.MarketInformation memory marketInfo = p2pSwap.getMarketMetadata(
            market
        );
        assertEq(marketInfo.ordersAvailable, 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA),
            input.amountA
        );
        if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
            // When tokenA is PRINCIPAL_TOKEN and hasPriorityFee is true, 
            // the contract accumulates one extra reward from the pay operation flow
            if (input.hasPriorityFee) {
                assertEq(
                    evvm.getBalance(address(p2pSwap), tokenA),
                    initialContractBalance + evvm.getRewardAmount()
                );
            } else {
                assertEq(
                    evvm.getBalance(address(p2pSwap), tokenA),
                    initialContractBalance
                );
            }
        } else {
            assertEq(evvm.getBalance(address(p2pSwap), tokenA), 0);
        }

        if (input.hasPriorityFee) {
            if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    priorityFee +
                        rewardAmountMateToken +
                        rewardAmountMateTokenCancel
                );
            } else {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    input.priorityFee
                );
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
                    rewardAmountMateToken + rewardAmountMateTokenCancel
                );
            }
        }
    }
}
