// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/* _______ __   __ _______ _______   _______ _______ _______ _______ 
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

    struct Input {
        string value;
        uint256 nonceNameService;
        uint64 priorityFee;
        uint256 nonceSyncEVVM;
        bool priorityEVVM;
    }

    function test__fuzz__addCustomMetadata__noStaker(
        Input memory input
    ) external {
        vm.assume(bytes(input.value).length > 0);

        vm.assume(
            input.nonceNameService <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(
            input.nonceSyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: input.value,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceSyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params.user,
            params.identity,
            params.value,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params.user.Address,
            params.identity,
            params.value,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
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
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "fisher balance incorrectly changed after adding custom metadata"
        );
    }

    function test__fuzz__addCustomMetadata__staker(
        Input memory input
    ) external {
        vm.assume(bytes(input.value).length > 0);

        vm.assume(
            input.nonceNameService <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(
            input.nonceSyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: input.value,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceSyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
            params.user,
            params.identity,
            params.value,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params.user.Address,
            params.identity,
            params.value,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
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
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (5 * evvm.getRewardAmount()) +
                ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
                params.priorityFee,
            "fisher balance incorrectly changed after adding custom metadata"
        );
    }
}
