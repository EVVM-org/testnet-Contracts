// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

contract fuzzTest_NameService_makeOffer is Test, Constants {
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
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool isAsyncExecEvvm;
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
        _executeFn_nameService_registrationUsername(
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

    struct Input {
        uint8 expiratonDateDays;
        uint32 amount;
        uint256 nonce;
        uint32 priorityFee;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEvvm;
    }

    function test__fuzz__preRegistrationUsername__noStaking(
        Input memory input
    ) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                )
        );
        vm.assume(input.nonceAsyncEVVM != input.nonce);

        vm.assume(input.expiratonDateDays > 1);
        vm.assume(input.amount > 1000);

        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp +
                (uint256(input.expiratonDateDays) * 1 days),
            amount: uint256(input.amount),
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: uint256(input.priorityFee),
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((uint256(params.amount) * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((uint256(params.amount) * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__fuzz__preRegistrationUsername__staking(
        Input memory input
    ) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                )
        );
        vm.assume(input.nonceAsyncEVVM != input.nonce);
        vm.assume(input.expiratonDateDays > 1);
        vm.assume(input.amount > 100);

        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp +
                (uint256(input.expiratonDateDays) * 1 days),
            amount: uint256(input.amount),
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: uint256(input.priorityFee),
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((uint256(params.amount) * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((uint256(params.amount) * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }
}
