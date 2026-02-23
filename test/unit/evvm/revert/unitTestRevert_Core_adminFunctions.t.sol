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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_Core_adminFunctions is Test, Constants {
    Core public coreMock;
    AccountData COMMON_USER = WILDCARD_USER;

    function setUp() public override {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        core = new Core(
            ADMIN.Address,
            address(staking),
            CoreStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        estimator = new Estimator(
            ACTIVATOR.Address,
            address(core),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(address(core), ADMIN.Address);

        staking.initializeSystemContracts(address(estimator), address(core));
        treasury = new Treasury(address(core));
        core.initializeSystemContracts(address(nameService), address(treasury));

        executeBeforeSetUp();
    }

    function addBalance(address user, address token, uint256 amount) private {
        core.addBalance(user, token, amount);
    }

    /**
     * Function to test:
     * nAdm: No admin execute the function
     * nNewAdm: No new admin execute the function
     * notInTime: Not in time to execute the function
     *
     */

    function test__unit_revert__constructor__AddressCantBeZero() external {
        uint256 sizeOfOpcode;
        address addressEvvmMock;
        vm.expectRevert(CoreError.AddressCantBeZero.selector);
        coreMock = new Core(
            address(0),
            address(staking),
            CoreStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        addressEvvmMock = address(coreMock);

        assembly {
            /// @dev check the size of the opcode of the address
            sizeOfOpcode := extcodesize(addressEvvmMock)
        }

        assertEq(
            sizeOfOpcode,
            0,
            "Evvm should not be deployed with zero address as admin"
        );

        vm.expectRevert(CoreError.AddressCantBeZero.selector);
        coreMock = new Core(
            ADMIN.Address,
            address(0),
            CoreStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 0,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        addressEvvmMock = address(coreMock);

        assembly {
            /// @dev check the size of the opcode of the address
            sizeOfOpcode := extcodesize(addressEvvmMock)
        }

        assertEq(
            sizeOfOpcode,
            0,
            "Evvm should not be deployed with zero address as staking contract"
        );
    }

    function test__unit_revert__setEvvmID__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.setEvvmID(1);
        vm.stopPrank();
    }

    function test__unit_revert__setEvvmID__WindowExpired() external {
        vm.startPrank(ADMIN.Address);
        core.setEvvmID(1);
        skip(26 hours);
        vm.expectRevert(CoreError.WindowExpired.selector);
        core.setEvvmID(67);
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unit_revert__proposeAdmin__IncorrectAddressInput() external {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(CoreError.IncorrectAddressInput.selector);
        core.proposeAdmin(address(0));
        vm.stopPrank();

        vm.startPrank(ADMIN.Address);
        vm.expectRevert(CoreError.IncorrectAddressInput.selector);
        core.proposeAdmin(ADMIN.Address);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposalAdmin__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.rejectProposalAdmin();

        vm.stopPrank();
    }

    function test__unit_revert__acceptAdmin__ProposalNotReadyToAccept() external {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(CoreError.ProposalNotReadyToAccept.selector);
        core.acceptAdmin();

        vm.stopPrank();
    }

    function test__unit_revert__acceptAdmin__SenderIsNotTheProposedAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);

        core.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        skip(200 days);

        vm.expectRevert(CoreError.SenderIsNotTheProposedAdmin.selector);
        core.acceptAdmin();

        vm.stopPrank();
    }

    /**
     *  @dev because this script behaves like a smart contract we dont
     *       need to implement a new contract
     */

    function test__unit_revert__proposeUserValidator__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.proposeUserValidator(address(125));
        vm.stopPrank();
    }

    function test__unit_revert__cancelUserValidatorProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeUserValidator(address(125));
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.cancelUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptUserValidatorProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeUserValidator(address(125));
        vm.stopPrank();
        skip(1 days);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.acceptUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptUserValidatorProposal__ProposalNotReadyToAccept()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeUserValidator(address(125));
        skip(10 minutes);
        vm.expectRevert(CoreError.ProposalNotReadyToAccept.selector);
        core.acceptUserValidatorProposal();
        vm.stopPrank();
    }

    function test__unit_revert__proposeListStatus__SenderIsNotAdmin() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.proposeListStatus(0x01);
        vm.stopPrank();
    }

    function test__unit_revert__proposeListStatus__InvalidListStatus()
        external
    {
        vm.startPrank(ADMIN.Address);
        vm.expectRevert(CoreError.InvalidListStatus.selector);
        core.proposeListStatus(0x03);
        vm.stopPrank();
    }

    function test__unit_revert__rejectListStatusProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.rejectListStatusProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptListStatusProposal__SenderIsNotAdmin()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01);
        vm.stopPrank();
        skip(1 days);
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.acceptListStatusProposal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptListStatusProposal_ProposalNotReadyToAccept()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01);
        skip(10 minutes);
        vm.expectRevert(CoreError.ProposalNotReadyToAccept.selector);
        core.acceptListStatusProposal();
        vm.stopPrank();
    }

    function test__unit_revert__setTokenStatusOnDenyList__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.setTokenStatusOnDenyList(address(67), true);
        vm.stopPrank();
    }

    function test__unit_revert__setTokenStatusOnAllowList__SenderIsNotAdmin()
        external
    {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert(CoreError.SenderIsNotAdmin.selector);
        core.setTokenStatusOnAllowList(address(67), true);
        vm.stopPrank();
    }
}

