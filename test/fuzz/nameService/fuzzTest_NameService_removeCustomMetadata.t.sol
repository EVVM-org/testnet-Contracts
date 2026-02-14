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

contract fuzzTest_NameService_removeCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
        uint256 key;
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bytes signatureEVVM;
    }

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            USER_USERNAME_OWNER,
            USERNAME,
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            ),
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

        for (uint256 i = 0; i < 100; i++) {
            _executeFn_nameService_addCustomMetadata(
                USER_USERNAME_OWNER,
                USERNAME,
                string.concat("test>", AdvancedStrings.uintToString(i)),
                address(0),
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                ) + i,
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000
                ) + i
            );
        }
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    struct Input {
        string identity;
        uint16 key;
        uint256 nonce;
        uint32 priorityFee;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEvvm;
    }

    function test__fuzz__removeCustomMetadata__noStaking(
        Input memory input
    ) external {
        input.key = uint16(bound(uint256(input.key), 0, 98));
        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000
                )
        );
        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000
                )
        );
        vm.assume(input.nonceAsyncEVVM != input.nonce);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: uint256(input.key),
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.nonceAsyncEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params.user,
            params.identity,
            params.key,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params.user.Address,
            params.identity,
            params.key,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params.identity, params.key);

        assertEq(
            customMetadata1,
            string.concat(
                "test>",
                AdvancedStrings.uintToString(uint256(input.key) + 1)
            ),
            "custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params.identity),
            99,
            "custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "fisher balance incorrectly changed after removing custom metadata"
        );
    }

    function test__fuzz__removeCustomMetadata__staking(
        Input memory input
    ) external {
        input.key = uint16(bound(uint256(input.key), 0, 98));
        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000
                )
        );
        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000
                )
        );
        vm.assume(input.nonceAsyncEVVM != input.nonce);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: uint256(input.key),
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.nonceAsyncEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params.user,
            params.identity,
            params.key,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params.user.Address,
            params.identity,
            params.key,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params.identity, params.key);

        assertEq(
            customMetadata1,
            string.concat(
                "test>",
                AdvancedStrings.uintToString(uint256(input.key) + 1)
            ),
            "custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params.identity),
            99,
            "custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (5 * core.getRewardAmount()) + uint256(params.priorityFee),
            "fisher balance incorrectly changed after removing custom metadata"
        );
    }
}
