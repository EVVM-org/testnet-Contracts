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

contract fuzzTest_NameService_flushCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
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

        for (uint256 i = 0; i < 10; i++) {
            _execute_makeAddCustomMetadata(
                USER_USERNAME_OWNER,
                USERNAME,
                string.concat("test>", AdvancedStrings.uintToString(i)),
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                ) + i,
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                ) + i,
                true
            );
        }
    }

    function _addBalance(
        AccountData memory user,
        string memory usernameToFlushCustomMetadata,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(
                usernameToFlushCustomMetadata
            ) + priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushCustomMetadata(
            usernameToFlushCustomMetadata
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    struct Input {
        uint256 nonceNameService;
        uint64 priorityFee;
        uint256 nonceAsyncEVVM;
        bool priorityEVVM;
    }

    function test__fuzz__flushCustomMetadata_noStaker(
        Input memory input
    ) external {
        vm.assume(
            input.nonceNameService <
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

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.identity, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
            params.user,
            params.identity,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.flushCustomMetadata(
            params.user.Address,
            params.identity,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(params.identity),
            0,
            "amount of custom metadata after flushCustomMetadata is incorrect"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance after flushCustomMetadata is incorrect"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "fisher balance after flushCustomMetadata is incorrect"
        );
    }

    function test__fuzz__flushCustomMetadata_staker(
        Input memory input
    ) external {
        vm.assume(
            input.nonceNameService <
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

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        uint256 sizeOfCustomMetadata = nameService.getAmountOfCustomMetadata(
            params.identity
        );

        _addBalance(params.user, params.identity, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
            params.user,
            params.identity,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.flushCustomMetadata(
            params.user.Address,
            params.identity,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(params.identity),
            0,
            "amount of custom metadata after flushCustomMetadata is incorrect"
        );

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance after flushCustomMetadata is incorrect"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * sizeOfCustomMetadata) +
                params.priorityFee,
            "fisher balance after flushCustomMetadata is incorrect"
        );
    }
}
