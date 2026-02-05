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
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    NameServiceError
} from "@evvm/testnet-contracts/library/errors/NameServiceError.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";

contract unitTestRevert_NameService_withdrawOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            )
        );

        offerID = _execute_makeMakeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            ),
            true,
            COMMON_USER_NO_STAKER_3
        );
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            priorityFeeAmount
        );

        return priorityFeeAmount;
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_evvmID()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                "test",
                offerID,
                nonceNameService
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_2,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            0,
            totalPriorityFee,
            nonceEVVM,
            true,
            address(nameService)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidSignatureOnNameService.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_signer()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_3,
                "test",
                offerID,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidSignatureOnNameService.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_username()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                /* 🢃 different username 🢃 */
                "differentTest",
                offerID,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidSignatureOnNameService.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_offerId()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                /* 🢃 different offerId 🢃 */
                offerID + 1,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidSignatureOnNameService.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                /* 🢃 different nameServiceNonce 🢃 */
                nonceNameService + 1,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidSignatureOnNameService.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__UserIsNotOwnerOfOffer()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                /* 🢃 non owner address 🢃 */
                COMMON_USER_NO_STAKER_3,
                "test",
                offerID,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfOffer.selector);
        nameService.withdrawOffer(
            /* 🢃 non owner address 🢃 */
            COMMON_USER_NO_STAKER_3.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__AsyncNonceAlreadyUsed()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        /* 🢃 reused nonce 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
        );
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignature_fromEvvm()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                nonceNameService,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFee + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1,
                /* 🢃 different priorityFlag 🢃 */
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InsufficientBalance_fromEvvm()
        external
    {
        uint256 totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        uint256 nonceNameService = 1001;
        uint256 nonceEVVM = 2002;
        /* 🢃 insufficient balance 🢃 */
        totalPriorityFee += 1 ether;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                nonceNameService,
                totalPriorityFee,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            nonceNameService,
            signatureNameService,
            totalPriorityFee,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        totalPriorityFee -= 1 ether;

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }
}
