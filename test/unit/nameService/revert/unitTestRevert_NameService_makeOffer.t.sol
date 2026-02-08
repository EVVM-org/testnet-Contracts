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
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";

contract unitTestRevert_NameService_makeOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

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
    }

    function _addBalance(
        AccountData memory user,
        uint256 offerAmount,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalOfferAmount, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            offerAmount + priorityFeeAmount
        );

        return (offerAmount, priorityFeeAmount);
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_evvmID()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                "test",
                expirationDate,
                totalOfferAmount,
                10001
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_2,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            totalOfferAmount,
            priorityFeeAmount,
            address(nameService),
            101,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_signer()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_3,
                "test",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_username()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                /* 🢃 different username 🢃 */
                "differentusername",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_dateExpire()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                /* 🢃 different dateExpire 🢃 */
                expirationDate + 1,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_amount()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                /* 🢃 different amount 🢃 */
                totalOfferAmount + 1,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                /* 🢃 different nameServiceNonce 🢃 */
                67,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(
            NameServiceError.InvalidSignatureOnNameService.selector
        );
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidUsername_flagNotAUsername()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_3,
            "testrevert",
            67,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffA
            )
        );

        /* 🢃 flagNotAUsername == 0x01 🢃 */
        string memory invalidUsername = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(
                keccak256(abi.encodePacked("testrevert", uint256(67)))
            )
        );

        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                invalidUsername,
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidUsername.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            invalidUsername,
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(invalidUsername, 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidUsername_verifyIfIdentityExists()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        /* 🢃 unregistered username 🢃 */
        string memory unregisteredUsername = "testrevert";
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                unregisteredUsername,
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.InvalidUsername.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            unregisteredUsername,
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(unregisteredUsername, 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__CannotBeBeforeCurrentTime()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        /* 🢃 expirationDate before current time 🢃 */
        uint256 expirationDate = block.timestamp - 1;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.CannotBeBeforeCurrentTime.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__AmountMustBeGreaterThanZero()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            /* 🢃 amount == 0 🢃 */
            0 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.AmountMustBeGreaterThanZero.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__AsyncNonceAlreadyUsed() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        /* 🢃 reuse nonce 🢃 */
        uint256 nonceToUse = 10001;

        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_2,
            "testrevert",
            67,
            nonceToUse
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                nonceToUse,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            nonceToUse,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InvalidSignature_fromEvvm()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                /* 🢃 different evvm nonce 🢃 */
                67,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }

    function test__unit_revert__makeOffer__InsufficientBalance_fromEvvm()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        uint256 expirationDate = block.timestamp + 30 days;

        /* 🢃 insufficient balance 🢃 */
        totalOfferAmount += 1 ether;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                expirationDate,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            expirationDate,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(
            checkData.offerer,
            address(0),
            "Offerer address should be zero"
        );
        assertEq(checkData.amount, 0, "Offer amount should be zero");
        assertEq(checkData.expireDate, 0, "Offer expire date should be zero");

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount - 1 ether + priorityFeeAmount,
            "User balance should be the same after revert"
        );
    }
}
