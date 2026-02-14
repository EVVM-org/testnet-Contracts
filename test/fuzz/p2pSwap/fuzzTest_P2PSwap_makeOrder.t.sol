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
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
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

contract fuzzTest_P2PSwap_makeOrder is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }

    struct MakeOrderFuzzTestInput {
        bool hasPriorityFee;
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
        vm.assume(input.nonceEVVM != input.nonceP2PSwap);

        // Form inputs
        // alternate tokens
        address tokenA = input.tokenScenario
            ? ETHER_ADDRESS
            : PRINCIPAL_TOKEN_ADDRESS;
        address tokenB = input.tokenScenario
            ? PRINCIPAL_TOKEN_ADDRESS
            : ETHER_ADDRESS;

        uint256 priorityFee = input.hasPriorityFee ? input.priorityFee : 0;
        uint256 nonceEVVM = input.nonceEVVM ;
        P2PSwapStructs.MetadataMakeOrder memory metadata = P2PSwapStructs
            .MetadataMakeOrder({
                nonce: input.nonceP2PSwap,
                originExecutor: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                amountA: input.amountA,
                amountB: input.amountB
            });
        uint256 rewardAmountMateToken = priorityFee > 0
            ? (core.getRewardAmount() * 3)
            : (core.getRewardAmount() * 2);

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
                core.getEvvmID(),
                address(p2pSwap),
                address(0),
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
                core.getEvvmID(),
                address(core),
                address(p2pSwap),
                "",
                tokenA,
                input.amountA,
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

        // execute tx
        vm.startPrank(COMMON_USER_STAKER.Address);
        (uint256 market, uint256 orderId) = p2pSwap.makeOrder(
            COMMON_USER_NO_STAKER_1.Address,
            metadata,
            signatureP2P,
            priorityFee,
            nonceEVVM,
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
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, tokenA),
            0 ether
        );
        if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
            assertEq(
                core.getBalance(address(p2pSwap), tokenA),
                input.amountA + initialContractBalance
            );
        } else {
            assertEq(core.getBalance(address(p2pSwap), tokenA), input.amountA);
        }

        if (input.hasPriorityFee) {
            if (tokenA == PRINCIPAL_TOKEN_ADDRESS) {
                assertEq(
                    core.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    input.priorityFee + rewardAmountMateToken
                );
            } else {
                assertEq(
                    core.getBalance(COMMON_USER_STAKER.Address, tokenA),
                    input.priorityFee
                );
                assertEq(
                    core.getBalance(COMMON_USER_STAKER.Address, tokenB),
                    rewardAmountMateToken
                );
            }
        }
    }
}
