// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM functions
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract unitTestCorrect_NameService_makeOffer is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;
    AccountData USER = COMMON_USER_NO_STAKER_2;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
        uint256 expiratonDate;
        uint256 amount;
        uint256 nonceNameService;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityEVVM;
        bytes signatureEVVM;
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
        totalOfferAmount = offerAmount;
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            USER_USERNAME_OWNER,
            USERNAME,
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

    function test__unit_correct__preRegistrationUsername__noStaking_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__noStaking_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__noStaking_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__noStaking_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonceNameService: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
            params.user,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.expiratonDate,
            params.amount,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expireDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }
}
