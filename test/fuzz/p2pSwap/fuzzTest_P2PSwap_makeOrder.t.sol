// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/*
:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     
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
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/P2PSwapStructs.sol";

contract fuzzTest_P2PSwap_makeOrder is Test, Constants {


    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;


    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    struct MakeOrderFuzzTestInput {
        bool hasPriorityFee;
        bool isAsync;
        uint16 amountA;
        uint16 amountB;
        uint16 priorityFee;
        uint16 nonceEVVM;
        uint16 nonceP2PSwap;
        bool tokenScenario;
    }

    function test__fuzz__makeOrder(
        MakeOrderFuzzTestInput memory input
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
        P2PSwapStructs.MetadataMakeOrder memory metadata = P2PSwapStructs
            .MetadataMakeOrder({
                nonce: input.nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                amountA: input.amountA,
                amountB: input.amountB
            });
        uint256 rewardAmountMateToken = priorityFee > 0
            ? (evvm.getRewardAmount() * 3)
            : (evvm.getRewardAmount() * 2);

        uint256 initialContractBalance = 50000000000000000000;

        // fund account
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

        // create signatures
        // swap
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOrder(
                evvm.getEvvmID(),
                input.nonceP2PSwap,
                tokenA,
                tokenB,
                input.amountA,
                input.amountB
            )
        );
        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        // pay
        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenA,
                input.amountA,
                priorityFee,
                nonceEVVM,
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
        (uint256 market, uint256 orderId) = p2pSwap.makeOrder(
            COMMON_USER_NO_STAKER_1.Address,
            metadata,
            signatureP2P,
            priorityFee,
            nonceEVVM,
            input.isAsync,
            signatureEVVM
        );
        vm.stopPrank();

        P2PSwap.MarketInformation memory marketInfo = p2pSwap.getMarketMetadata(
            market
        );
        assertEq(marketInfo.tokenA, tokenA);
        assertEq(marketInfo.tokenB, tokenB);
        assertEq(marketInfo.maxSlot, 1);
        assertEq(marketInfo.ordersAvailable, 1);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA),
            0 ether
        );
        if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
            assertEq(
                evvm.getBalance(address(p2pSwap), tokenA),
                input.amountA + initialContractBalance
            );
        } else {
            assertEq(evvm.getBalance(address(p2pSwap), tokenA), input.amountA);
        }

        if (input.hasPriorityFee) {
            if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    input.priorityFee + rewardAmountMateToken
                );
            } else {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    input.priorityFee
                );
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, tokenB),
                    rewardAmountMateToken
                );
            }
        }
    }
}
