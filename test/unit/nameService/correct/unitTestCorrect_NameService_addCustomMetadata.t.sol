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

contract unitTestCorrect_NameService_addCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    uint256 OFFER_ID;
    uint256 EXPIRATION_DATE = block.timestamp + 30 days;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
        string value;
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
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_correct__addCustomMetadata__noStaker() external {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonceNameService: 10001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>2",
            nonceNameService: 20002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 20002,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>3",
            nonceNameService: 30003,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>4",
            nonceNameService: 40004,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 40004,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.value,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.value,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, 0);

        assertEq(
            customMetadata1,
            params1.value,
            "Error 1: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            1,
            "Error 1: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.value,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.value,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, 1);

        assertEq(
            customMetadata2,
            params2.value,
            "Error 2: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            2,
            "Error 2: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params3.user, params3.priorityFee);

        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params3.user,
            params3.identity,
            params3.value,
            params3.nonceNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params3.user.Address,
            params3.identity,
            params3.value,
            params3.nonceNameService,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.priorityEVVM,
            params3.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata3 = nameService
            .getSingleCustomMetadataOfIdentity(params3.identity, 2);

        assertEq(
            customMetadata3,
            params3.value,
            "Error 3: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params3.identity),
            3,
            "Error 3: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params3.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 3: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 3: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params4.user, params4.priorityFee);

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params4.user,
            params4.identity,
            params4.value,
            params4.nonceNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params4.user.Address,
            params4.identity,
            params4.value,
            params4.nonceNameService,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.priorityEVVM,
            params4.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata4 = nameService
            .getSingleCustomMetadataOfIdentity(params4.identity, 3);

        assertEq(
            customMetadata4,
            params4.value,
            "Error 4: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params4.identity),
            4,
            "Error 4: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params4.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 4: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 4: fisher balance incorrectly changed after adding custom metadata"
        );
    }

    function test__unit_correct__addCustomMetadata__staker() external {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonceNameService: 10001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>2",
            nonceNameService: 20002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 20002,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>3",
            nonceNameService: 30003,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>4",
            nonceNameService: 40004,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 40004,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.value,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        uint256 amountToReward1 = (5 * evvm.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params1.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.value,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, 0);

        assertEq(
            customMetadata1,
            params1.value,
            "Error 1: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            1,
            "Error 1: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward1,
            "Error 1: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.value,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        uint256 amountToReward2 = (5 * evvm.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params2.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.value,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, 1);

        assertEq(
            customMetadata2,
            params2.value,
            "Error 2: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            2,
            "Error 2: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward2 + amountToReward1,
            "Error 2: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params3.user, params3.priorityFee);

        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params3.user,
            params3.identity,
            params3.value,
            params3.nonceNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.priorityEVVM
        );

        uint256 amountToReward3 = (5 * evvm.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params3.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params3.user.Address,
            params3.identity,
            params3.value,
            params3.nonceNameService,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.priorityEVVM,
            params3.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata3 = nameService
            .getSingleCustomMetadataOfIdentity(params3.identity, 2);

        assertEq(
            customMetadata3,
            params3.value,
            "Error 3: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params3.identity),
            3,
            "Error 3: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params3.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 3: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward3 + amountToReward2 + amountToReward1,
            "Error 3: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params4.user, params4.priorityFee);

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params4.user,
            params4.identity,
            params4.value,
            params4.nonceNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.priorityEVVM
        );

        uint256 amountToReward4 = (5 * evvm.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params4.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params4.user.Address,
            params4.identity,
            params4.value,
            params4.nonceNameService,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.priorityEVVM,
            params4.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata4 = nameService
            .getSingleCustomMetadataOfIdentity(params4.identity, 3);

        assertEq(
            customMetadata4,
            params4.value,
            "Error 4: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params4.identity),
            4,
            "Error 4: custom metadata slots incorrect"
        );

        assertEq(
            evvm.getBalance(params4.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 4: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward4 + amountToReward3 + amountToReward2 + amountToReward1,
            "Error 4: fisher balance incorrectly changed after adding custom metadata"
        );
    }
}
