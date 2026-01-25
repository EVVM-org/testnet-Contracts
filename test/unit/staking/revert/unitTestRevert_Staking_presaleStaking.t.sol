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
        evvm.addBalance(
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
        uint256 nonceEVVM;
        bool priorityFlagEVVM;
        bytes signatureEVVM;
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.PresaleStakingDisabled.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignatureOnStaking_evvmID()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
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
                evvm.getEvvmID() + 1,
                params.isStaking,
                1,
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signatureEVVM = _execute_makeSignaturePay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking(),
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            address(staking)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignatureOnStaking_signer()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            /* 🢃 Different Signer 🢃 */
            COMMON_USER_NO_STAKER_2,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignatureOnStaking_isStaking()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            /* 🢃 Different flag isStaking 🢃 */
            !params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignatureOnStaking_amountOfStaking()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                params.isStaking,
                /* 🢃 Different amount of staking 🢃 */
                67,
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signatureEVVM = _execute_makeSignaturePay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking(),
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            address(staking)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__InvalidSignatureOnStaking_nonce()
        external
    {
        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            /* 🢃 Different nonce 🢃 */
            params.nonceStake + 1,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignatureOnStaking.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_2.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.UserIsNotPresaleStaker.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__AsyncNonceAlreadyUsed()
        external
    {
        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            1000001000001,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.UserPresaleStakerLimitExceeded.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_maxLimit()
        external
    {
        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );
        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            222,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.UserPresaleStakerLimitExceeded.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_AddressMustWaitToFullUnstake()
        external
    {
        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: false,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.AddressMustWaitToFullUnstake.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }

    function test__unit_revert__presaleStaking__UserPresaleStakerLimitExceeded_AddressMustWaitToStakeAgain()
        external
    {
        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePresaleStaking(
            COMMON_USER_NO_STAKER_1,
            false,
            222,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: COMMON_USER_NO_STAKER_1,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.AddressMustWaitToStakeAgain.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                params.isStaking,
                1,
                params.nonceStake
            )
        );
        params.signatureStake = Erc191TestBuilder.buildERC191Signature(v, r, s);

        params.signatureEVVM = _execute_makeSignaturePay(
            params.user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            /* 🢃 Diferent amount 🢃 */
            staking.priceOfStaking() + 1,
            /* 🢃 Diferent priority fee 🢃 */
            params.priorityFee + 1,
            /* 🢃 Diferent nonce 🢃 */
            params.nonceEVVM + 1,
            params.priorityFlagEVVM,
            address(staking)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
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
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();
    }
}
