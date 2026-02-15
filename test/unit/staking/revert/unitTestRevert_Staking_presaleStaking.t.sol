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

contract unitTestRevert_Staking_presaleStaking is Test, Constants {
    function executeBeforeSetUp() internal override {
        /**
         *  @dev Because presale staking is disabled by default in 
                 testnet contracts, we need to enable it here
         */
        vm.startPrank(ADMIN.Address);

        staking.proposeSetSecondsToUnlockStaking(1 days);
        staking.prepareChangeAllowPresaleStaking();
        staking.prepareChangeAllowPublicStaking();

        skip(1 days);

        staking.confirmChangeAllowPresaleStaking();
        staking.confirmChangeAllowPublicStaking();
        staking.acceptSetSecondsToUnlockStaking();

        assertFalse(
            staking.getAllowPublicStaking().flag,
            "public staking was not disabled in setup"
        );
        assertTrue(
            staking.getAllowPresaleStaking().flag,
            "presale staking was not enabled in setup"
        );

        ///@dev Adding a presale staker to be able to execute
        ///     presale staking tests
        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function _addBalance(
        address user,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        core.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking()) + priorityFee
        );
        return (staking.priceOfStaking(), priorityFee);
    }

    struct Params {
        AccountData user;
        bool isStaking;
        uint256 nonceStake;
        uint256 _amountInPrincipal;
        bytes signatureStake;
        uint256 priorityFee;
        uint256 noncePay;
        bytes signaturePay;
    }

    function test__unit_revert__presaleStaking__PresaleStakingDisabled_allowPresaleStaking()
        external
    {
        /* 🢃 Disabling presale staking 🢃 */
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPresaleStaking();
        skip(1 days);
        staking.confirmChangeAllowPresaleStaking();
        vm.stopPrank();

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__PresaleStakingDisabled_allowPublicStaking()
        external
    {
        /* 🢃 Enable public staking 🢃 */
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__PresaleStakingDisabled_bothFlags()
        external
    {
        /* 🢃 Changing flags 🢃 */
        vm.startPrank(ADMIN.Address);
        staking.prepareChangeAllowPublicStaking();
        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPresaleStaking();
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_evvmID()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                /* 🢃 Diferent EvvmID 🢃 */
                core.getEvvmID() + 1,
                address(staking),
                params.isStaking,
                1,
                address(0),
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signaturePay = _executeSig_evvm_pay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking(),
            params.priorityFee,
            address(staking),
            params.noncePay,
            true
        );
    

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_signer()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            /* 🢃 Different Signer 🢃 */
            COMMON_USER_NO_STAKER_2,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_isStaking()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            /* 🢃 Different flag isStaking 🢃 */
            !params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_amountOfStaking()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                core.getEvvmID(),
                address(staking),
                params.isStaking,
                /* 🢃 Different amount of staking 🢃 */
                67,
                address(0),
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signaturePay = _executeSig_evvm_pay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking(),
            params.priorityFee,
            address(staking),
            params.noncePay,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_nonce()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,address(0),
            /* 🢃 Different nonce 🢃 */
            params.nonceStake + 1,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserIsNotPresaleStaker()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_2,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.UserIsNotPresaleStaker.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__AsyncNonceAlreadyUsed()
        external
    {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 0);
        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            1000001000001,
            0,
            33,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.AsyncNonceAlreadyUsed.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_zero()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: false,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.UserPresaleStakerLimitExceeded.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_maxLimit()
        external
    {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 0);
        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            111,
            0,
            1111,
            GOLDEN_STAKER
        );
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 0);
        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            222,
            0,
            2222,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.UserPresaleStakerLimitExceeded.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_AddressMustWaitToFullUnstake()
        external
    {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 0);
        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            111,
            0,
            1111,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: false,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.AddressMustWaitToFullUnstake.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_AddressMustWaitToStakeAgain()
        external
    {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, 0);
        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            address(0),
            111,
            0,
            1111,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_presaleStaking(
            COMMON_USER_NO_STAKER_1,
            false,
            address(0),
            222,
            0,
            2222,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(StakingError.AddressMustWaitToStakeAgain.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignature_onEvvm()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                core.getEvvmID(),
                address(staking),
                params.isStaking,
                1,
                address(0),
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signaturePay = _executeSig_evvm_pay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            /* 🢃 Diferent amount 🢃 */
            staking.priceOfStaking() + 1,
            /* 🢃 Diferent priority fee 🢃 */
            params.priorityFee + 1,
            address(staking),
            /* 🢃 Diferent nonce 🢃 */
            params.noncePay + 1,
            /* 🢃 Diferent isAsyncExec 🢃 */
            false
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InsufficientBalance_onEvvm()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            noncePay: 67,
            signaturePay: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signaturePay
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(CoreError.InsufficientBalance.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            address(0),
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );
        vm.stopPrank();
    }
}
