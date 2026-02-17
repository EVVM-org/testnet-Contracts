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
import "@evvm/testnet-contracts/library/errors/StakingError.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";
import "@evvm/testnet-contracts/library/structs/StakingStructs.sol";
import "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_Staking_goldenStaking is Test, Constants {
    function executeBeforeSetUp() internal override {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(1 days);
        skip(1 days);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();
    }

    function _addBalance(
        address user,
        uint256 stakingAmount
    ) private returns (uint256 amount) {
        core.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount)
        );

        amount = (staking.priceOfStaking() * stakingAmount);
    }

    function test__unitRevert__goldenStaking__SenderIsNotGoldenFisher()
        external
    {
        (uint256 amount) = _addBalance(COMMON_USER_NO_STAKER_1.Address, 1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amount,
                0,
                address(staking),
                core.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            )
        );
        bytes memory signaturePay = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(StakingError.SenderIsNotGoldenFisher.selector);
        staking.goldenStaking(true, 1, signaturePay);

        vm.stopPrank();
    }

    function test__unitRevert__goldenStaking__AddressMustWaitToFullUnstake()
        external
    {
        _addBalance(GOLDEN_STAKER.Address, 10);

        bytes memory signaturePaystake = _executeSig_staking_goldenStaking(
            true,
            10
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(true, 10, signaturePaystake);

        vm.expectRevert(StakingError.AddressMustWaitToFullUnstake.selector);

        staking.goldenStaking(false, 10, "");

        vm.stopPrank();
    }

    function test__unitRevert__goldenStaking__AddressMustWaitToStakeAgain()
        external
    {
        _addBalance(GOLDEN_STAKER.Address, 10);

        bytes memory signaturePay1 = _executeSig_staking_goldenStaking(
            true,
            10
        );

        bytes memory signaturePay2 = _executeSig_staking_goldenStaking(
            true,
            10
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(true, 10, signaturePay1);

        skip(staking.getSecondsToUnlockFullUnstaking());

        staking.goldenStaking(false, 10, "");

        vm.expectRevert(StakingError.AddressMustWaitToStakeAgain.selector);

        staking.goldenStaking(true, 10, signaturePay2);

        vm.stopPrank();
    }

    function test__unitRevert__goldenStaking__InvalidSignature_evvm() external {
        _addBalance(GOLDEN_STAKER.Address, 10);

        bytes memory signaturePay = _executeSig_evvm_pay(
            GOLDEN_STAKER,
            address(staking),
            "",
            /* 🢃 Diferent token 🢃 */
            ETHER_ADDRESS,
            /* 🢃 Diferent amount 🢃 */
            10000000,
            /* 🢃 Different priorityFee (pf>0) 🢃 */
            100,
            address(staking),
            core.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
            false
        );

        vm.startPrank(GOLDEN_STAKER.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.goldenStaking(true, 10, signaturePay);

        vm.stopPrank();
    }
}
