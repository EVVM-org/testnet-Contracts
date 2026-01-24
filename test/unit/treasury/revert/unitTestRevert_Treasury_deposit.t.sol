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

import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/treasury/lib/ErrorsLib.sol";

contract unitTestRevert_Treasury_deposit is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        testToken = new TestERC20();
    }

    function test__unit_revert__deposit__hostNative__DepositAmountMustBeGreaterThanZero()
        external
    {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(ErrorsLib.DepositAmountMustBeGreaterThanZero.selector);

        treasury.deposit{value: 0 ether}(address(0), 0 ether);

        vm.stopPrank();
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0
        );
        assertEq(COMMON_USER_NO_STAKER_1.Address.balance, 0.01 ether);
        assertEq(address(treasury).balance, 0 ether);
    }

    function test__unit_revert__deposit__hostNative__InvalidDepositAmount()
        external
    {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(ErrorsLib.InvalidDepositAmount.selector);
        treasury.deposit{value: 0.01 ether}(address(0), 0.001 ether);

        vm.stopPrank();
        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0
        );
        assertEq(COMMON_USER_NO_STAKER_1.Address.balance, 0.01 ether);
        assertEq(address(treasury).balance, 0 ether);
    }

    function test__unit_revert__deposit__token__InvalidDepositAmount()
        external
    {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        vm.expectRevert(ErrorsLib.InvalidDepositAmount.selector);
        treasury.deposit{value: 0.01 ether}(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            0
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            10 ether
        );
        assertEq(testToken.balanceOf(address(treasury)), 0 ether);
    }

    function test__unit_revert__deposit__token_DepositAmountMustBeGreaterThanZero()
        external
    {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        vm.expectRevert(ErrorsLib.DepositAmountMustBeGreaterThanZero.selector);
        treasury.deposit(address(testToken), 0);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            0
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            10 ether
        );
        assertEq(testToken.balanceOf(address(treasury)), 0 ether);
    }

    function test__unit_revert__deposit__token__NoAllowance() external {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert();
        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                address(testToken)
            ),
            0
        );
        assertEq(
            testToken.balanceOf(COMMON_USER_NO_STAKER_1.Address),
            10 ether
        );
        assertEq(testToken.balanceOf(address(treasury)), 0 ether);
    }
}
