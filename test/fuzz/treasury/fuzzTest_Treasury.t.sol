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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract fuzzTest_Treasury is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        testToken = new TestERC20();
    }

    function _addBalance(
        address user,
        uint256 amount,
        address token
    ) private returns (uint256) {
        evvm.addBalance(user, token, amount);

        return amount;
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
            input.depositAmount,
            "Error: incorrect balance after deposit"
        );
        if (input.isHostNative) {
            assertEq(
                address(treasury).balance,
                input.depositAmount,
                "Error: incorrect treasury balance after deposit"
            );
            assertEq(
                address(input.user).balance,
                0,
                "Error: incorrect user balance after deposit"
            );
        } else {
            assertEq(
                testToken.balanceOf(address(treasury)),
                input.depositAmount,
                "Error: incorrect treasury token balance after deposit"
            );
            assertEq(
                testToken.balanceOf(input.user),
                0,
                "Error: incorrect user token balance after deposit"
            );
        }
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
            vm.deal(address(treasury), input.withdrawAmount);
            _addBalance(input.user, input.withdrawAmount, ETHER_ADDRESS);
        } else {
            testToken.mint(address(treasury), input.withdrawAmount);
            _addBalance(input.user, input.withdrawAmount, address(testToken));
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
            0,
            "Error: incorrect balance after withdraw"
        );

        if (input.isHostNative) {
            assertEq(
                address(treasury).balance,
                0,
                "Error: incorrect treasury balance after withdraw"
            );
            assertEq(
                address(input.user).balance,
                input.withdrawAmount,
                "Error: incorrect user balance after withdraw"
            );
        } else {
            assertEq(
                testToken.balanceOf(address(treasury)),
                0,
                "Error: incorrect treasury token balance after withdraw"
            );
            assertEq(
                testToken.balanceOf(input.user),
                input.withdrawAmount,
                "Error: incorrect user token balance after withdraw"
            );
        }
    }
}
