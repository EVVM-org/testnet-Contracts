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

contract fuzzTest_NameService_acceptOffer is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;
    AccountData USER = COMMON_USER_NO_STAKER_2;

    uint256 AMOUNT_OFFER = 1 ether;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
        uint256 offerID;
        uint256 nonceNameService;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityEVVM;
        bytes signatureEVVM;
    }

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            USER_USERNAME_OWNER,
            USERNAME,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
            )
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

    struct Input {
        // makeOffer parameters
        uint128 amountToOffer;
        uint8 expirationDateDays;
        // acceptOffer parameters
        uint256 nonceNameService;
        uint32 priorityFeeAmountEVVM;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEVVM;
    }

    function test__fuzz__acceptOffer__noStaker(Input memory input) external {
        vm.assume(input.amountToOffer > 0);
        vm.assume(input.expirationDateDays > 0);
        vm.assume(
            input.nonceNameService <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );
        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        uint offerID = _execute_makeMakeOffer(
            USER,
            USERNAME,
            block.timestamp + (uint256(input.expirationDateDays) * 1 days),
            input.amountToOffer,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: offerID,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: uint256(input.priorityFeeAmountEVVM),
            nonceEVVM: input.isAsyncExecEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            priorityEVVM: input.isAsyncExecEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
            params.user,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.prank(FISHER_NO_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expireDate,
            block.timestamp + (uint256(input.expirationDateDays) * 1 days),
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((uint256(input.amountToOffer) * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed"
        );
    }

    function test__fuzz__acceptOffer__staker(Input memory input) external {
        vm.assume(input.amountToOffer > 0);
        vm.assume(input.expirationDateDays > 0);
        vm.assume(
            input.nonceNameService <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );
        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        uint offerID = _execute_makeMakeOffer(
            USER,
            USERNAME,
            block.timestamp + (uint256(input.expirationDateDays) * 1 days),
            input.amountToOffer,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            true,
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: offerID,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: uint256(input.priorityFeeAmountEVVM),
            nonceEVVM: input.isAsyncExecEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            priorityEVVM: input.isAsyncExecEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
            params.user,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.prank(FISHER_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expireDate,
            block.timestamp + (uint256(input.expirationDateDays) * 1 days),
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((uint256(input.amountToOffer) * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount()) +
                (((uint256(checkData.amount) * 1) / 199) / 4) +
                uint256(params.priorityFee)),
            "Error staker: balance incorrectly changed"
        );
    }
}
