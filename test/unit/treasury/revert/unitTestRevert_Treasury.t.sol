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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    TreasuryError
} from "@evvm/testnet-contracts/library/errors/TreasuryError.sol";
import {
    CoreError
} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_Treasury is Test, Constants {
    TestERC20 testToken;

    function executeBeforeSetUp() internal override {
        testToken = new TestERC20();
    }

    function _addBalance(
        address user,
        uint256 amount,
        address token
    ) private returns (uint256) {
        core.addBalance(user, token, amount);

        return amount;
    }

    function test__unit_revert__deposit__hostNative__DepositAmountMustBeGreaterThanZero()
        external
    {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(
            TreasuryError.DepositAmountMustBeGreaterThanZero.selector
        );

        treasury.deposit{value: 0 ether}(address(0), 0 ether);

        vm.stopPrank();
    }

    function test__unit_revert__deposit__hostNative__InvalidDepositAmount()
        external
    {
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(TreasuryError.InvalidDepositAmount.selector);
        treasury.deposit{value: 0.01 ether}(address(0), 0.001 ether);

        vm.stopPrank();
        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, address(0)),
            0
        );
        assertEq(COMMON_USER_NO_STAKER_1.Address.balance, 0.01 ether);
        assertEq(address(treasury).balance, 0 ether);
    }

    function test__unit_revert__deposit__token__DepositCoinWithToken()
        external
    {
        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);
        vm.deal(COMMON_USER_NO_STAKER_1.Address, 0.01 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        vm.expectRevert(TreasuryError.DepositCoinWithToken.selector);
        treasury.deposit{value: 0.01 ether}(address(testToken), 10 ether);

        vm.stopPrank();

        assertEq(
            core.getBalance(
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

        vm.expectRevert(
            TreasuryError.DepositAmountMustBeGreaterThanZero.selector
        );
        treasury.deposit(address(testToken), 0);

        vm.stopPrank();

        assertEq(
            core.getBalance(
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
            core.getBalance(
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

    function test__unit_revert__withdraw__PrincipalTokenIsNotWithdrawable()
        external
    {
        _addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            10 ether,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(TreasuryError.PrincipalTokenIsNotWithdrawable.selector);
        treasury.withdraw(PRINCIPAL_TOKEN_ADDRESS, 1 ether);

        vm.stopPrank();
    }

    function test__unit_revert__withdraw__InsufficientBalance() external {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 1 ether, ETHER_ADDRESS);
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(TreasuryError.InsufficientBalance.selector);
        treasury.withdraw(ETHER_ADDRESS, 2 ether);

        vm.stopPrank();
    }


    function test__unit_revert__withdraw__TokenIsDeniedForExecution_denyList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x02); // Activate denyList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        core.setTokenStatusOnDenyList(address(testToken), true);
        vm.stopPrank();

        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        vm.expectRevert(CoreError.TokenIsDeniedForExecution.selector);
        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();
    }


    function test__unit_revert__withdraw__TokenIsDeniedForExecution_allowList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01); // Activate allowList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        vm.stopPrank();

        testToken.mint(COMMON_USER_NO_STAKER_1.Address, 10 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        testToken.approve(address(treasury), 10 ether);

        vm.expectRevert(CoreError.TokenIsDeniedForExecution.selector);
        treasury.deposit(address(testToken), 10 ether);

        vm.stopPrank();
    }
}
