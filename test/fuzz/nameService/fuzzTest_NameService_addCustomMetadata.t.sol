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

contract fuzzTest_NameService_addCustomMetadata is Test, Constants {
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
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 noncePay;
        bytes signaturePay;
    }

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            USER_USERNAME_OWNER,
            USERNAME,
            444,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            address(0),
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
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    struct Input {
        string value;
        uint256 nonce;
        uint64 priorityFee;
        uint256 nonceSyncEVVM;
        bool isAsyncExecEvvm;
    }

    function test__fuzz__addCustomMetadata__noStaker(
        Input memory input
    ) external {
        vm.assume(bytes(input.value).length > 0);

        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
                )
        );

        vm.assume(
            input.nonceSyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(input.nonce != input.nonceSyncEVVM);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: input.value,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            noncePay: input.nonceSyncEVVM,
            signaturePay: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signaturePay
        ) = _executeSig_nameService_addCustomMetadata(
            params.user,
            params.identity,
            params.value,
            address(0),
            params.nonce,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params.user.Address,
            params.identity,
            params.value,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params.identity, 0);

        assertEq(
            customMetadata1,
            params.value,
            "custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params.identity),
            1,
            "custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "fisher balance incorrectly changed after adding custom metadata"
        );
    }

    function test__fuzz__addCustomMetadata__staker(
        Input memory input
    ) external {
        vm.assume(bytes(input.value).length > 0);

        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
                )
        );

        vm.assume(
            input.nonceSyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(input.nonce != input.nonceSyncEVVM);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: input.value,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            noncePay: input.nonceSyncEVVM,
            signaturePay: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signaturePay
        ) = _executeSig_nameService_addCustomMetadata(
            params.user,
            params.identity,
            params.value,
            address(0),
            params.nonce,
            params.priorityFee,
            params.noncePay
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params.user.Address,
            params.identity,
            params.value,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.noncePay,
            params.signaturePay
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params.identity, 0);

        assertEq(
            customMetadata1,
            params.value,
            "custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params.identity),
            1,
            "custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (5 * core.getRewardAmount()) +
                ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
                params.priorityFee,
            "fisher balance incorrectly changed after adding custom metadata"
        );
    }
}
