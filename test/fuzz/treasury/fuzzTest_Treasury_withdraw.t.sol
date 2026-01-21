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

contract fuzzTest_Treasury_withdraw is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        testToken = new TestERC20();
    }

    function depositHostNative(address user, uint256 amount) internal {
        vm.deal(user, amount);

        vm.startPrank(user);

        treasury.deposit{value: amount}(address(0), amount);

        vm.stopPrank();
    }

    function depositToken(address user, uint256 amount) internal {
        testToken.mint(user, amount);

        vm.startPrank(user);

        testToken.approve(address(treasury), amount);

        treasury.deposit(address(testToken), amount);

        vm.stopPrank();
    }

    struct withdrawFuzzTestInput {
        bool isHostNative;
        uint24 withdrawAmount;
        address user;
    }

    function test__fuzz__withdraw(withdrawFuzzTestInput memory input) external {
        vm.assume(input.user != address(1) && input.user != address(treasury));
        vm.assume(input.withdrawAmount > 0);

        if (input.isHostNative) {
            depositHostNative(input.user, input.withdrawAmount);
        } else {
            depositToken(input.user, input.withdrawAmount);
        }

        vm.startPrank(input.user);

        treasury.withdraw(
            input.isHostNative ? address(0) : address(testToken),
            input.withdrawAmount
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                input.user,
                (address(input.isHostNative ? address(0) : address(testToken)))
            ),
            0
        );

        if (input.isHostNative) {
            assertEq(address(treasury).balance, 0);
            assertEq(address(input.user).balance, input.withdrawAmount);
        } else {
            assertEq(testToken.balanceOf(address(treasury)), 0);
            assertEq(testToken.balanceOf(input.user), input.withdrawAmount);
        }
    }
}
