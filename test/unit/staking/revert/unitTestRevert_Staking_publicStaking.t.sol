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
import "@evvm/testnet-contracts/contracts/staking/lib/ErrorsLib.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    ErrorsLib as EvvmErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";

contract unitTestRevert_Staking_publicStaking is Test, Constants {
    AccountData USER = COMMON_USER_NO_STAKER_1;

    function executeBeforeSetUp() internal override {
        vm.startPrank(ADMIN.Address);

        staking.proposeSetSecondsToUnlockStaking(1 days);

        skip(1 days);

        staking.acceptSetSecondsToUnlockStaking();
    }

    function _addBalance(
        AccountData memory user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount) + priorityFee
        );
        return ((staking.priceOfStaking() * stakingAmount), priorityFee);
    }

    struct Params {
        AccountData user;
        bool isStaking;
        uint256 amountOfStaking;
        uint256 nonce;
        bytes signatureStaking;
        uint256 priorityFeeEVVM;
        uint256 nonceEVVM;
        bool priorityFlagEVVM;
        bytes signatureEVVM;
    }

    function test__unit_revert__publicStaking__PublicStakingDisabled()
        external
    {
        /* 🢃 Disable public staking 🢃 */
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(
            abi.encodeWithSelector(ErrorsLib.PublicStakingDisabled.selector)
        );
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__InvalidSignatureOnStaking_evvmID()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                /* 🢃 Diferent evvmID 🢃 */
                evvm.getEvvmID() + 1,
                params.isStaking,
                params.amountOfStaking,
                params.nonce
            )
        );
        params.signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        params.signatureEVVM = _execute_makeSignaturePay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking() * params.amountOfStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            address(staking)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__InvalidSignatureOnStaking_signer()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            /* 🢃 Different signer 🢃 */
            COMMON_USER_NO_STAKER_2,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__InvalidSignatureOnStaking_isStaking()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            /* 🢃 Different isStaking 🢃 */
            !params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__InvalidSignatureOnStaking_amountOfStaking()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            /* 🢃 Different amountOfStaking 🢃 */
            params.amountOfStaking + 1,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__InvalidSignatureOnStaking_nonce()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            /* 🢃 Different nonce 🢃 */
            params.nonce + 1,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__AsyncNonceAlreadyUsed()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            100001,
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__AddressMustWaitToFullUnstake()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            111,
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: false,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.AddressMustWaitToFullUnstake.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__publicStaking__AddressMustWaitToStakeAgain()
        external
    {
        _execute_makePublicStaking(
            USER,
            true,
            10,
            111,
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePublicStaking(
            USER,
            false,
            10,
            112,
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.AddressMustWaitToStakeAgain.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }


    function test__unit_revert__publicStaking__InvalidSignature_onEvvm()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(
            params.user,
            params.amountOfStaking,
            params.priorityFeeEVVM
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                params.isStaking,
                params.amountOfStaking,
                params.nonce
            )
        );
        params.signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        params.signatureEVVM = _execute_makeSignaturePay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            /* 🢃 Different amount 🢃 */
            staking.priceOfStaking() * params.amountOfStaking + 1,
            /* 🢃 Different priorityFee 🢃 */
            params.priorityFeeEVVM+1,
            /* 🢃 Different nonceEVVM 🢃 */
            params.nonceEVVM + 1,
            params.priorityFlagEVVM,
            address(staking)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }
    
    
    function test__unit_revert__publicStaking__InsufficientBalance_onEvvm()
        external
    {
        Params memory params = Params({
            user: USER,
            isStaking: true,
            amountOfStaking: 10,
            nonce: 100001,
            signatureStaking: "",
            priorityFeeEVVM: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: ""
        });

        (
            params.signatureStaking,
            params.signatureEVVM
        ) = _execute_makePublicStakingSignature(
            params.user,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        staking.publicStaking(
            params.user.Address,
            params.isStaking,
            params.amountOfStaking,
            params.nonce,
            params.signatureStaking,
            params.priorityFeeEVVM,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }
    
}
