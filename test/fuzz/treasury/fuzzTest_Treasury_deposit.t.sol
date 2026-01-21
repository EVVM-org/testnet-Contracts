// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants, TestERC20} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_Treasury_deposit is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        testToken = new TestERC20();
    }

    struct depositFuzzTestInput {
        bool isHostNative;
        uint24 depositAmount;
        address user;
    }

    function test__fuzz__deposit(depositFuzzTestInput memory input) external {
        vm.assume(input.user != address(0) && input.user != address(treasury));
        vm.assume(input.depositAmount > 0);

        if (input.isHostNative) {
            vm.deal(input.user, input.depositAmount);
        } else {
            testToken.mint(input.user, input.depositAmount);
        }

        vm.startPrank(input.user);
        if (input.isHostNative) {
            treasury.deposit{value: input.depositAmount}(
                address(0),
                input.depositAmount
            );
        } else {
            testToken.approve(address(treasury), input.depositAmount);

            treasury.deposit(address(testToken), input.depositAmount);
        }

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                input.user,
                (address(input.isHostNative ? address(0) : address(testToken)))
            ),
            input.depositAmount
        );
        if (input.isHostNative) {
            assertEq(address(treasury).balance, input.depositAmount);
            assertEq(address(input.user).balance, 0);
        } else {
            assertEq(
                testToken.balanceOf(address(treasury)),
                input.depositAmount
            );
            assertEq(testToken.balanceOf(input.user), 0);
        }
    }
}
