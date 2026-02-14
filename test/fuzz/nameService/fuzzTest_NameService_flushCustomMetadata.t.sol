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

contract fuzzTest_NameService_flushCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
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

        for (uint256 i = 0; i < 10; i++) {
            _executeFn_nameService_addCustomMetadata(
                USER_USERNAME_OWNER,
                USERNAME,
                string.concat("test>", AdvancedStrings.uintToString(i)),
                address(0),
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                ) + i,
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
                ) + i
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
        core.addBalance(
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
        uint256 nonce;
        uint64 priorityFee;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEvvm;
    }

    function test__fuzz__flushCustomMetadata_noStaker(
        Input memory input
    ) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
                )
        );

        vm.assume(input.nonce != input.nonceAsyncEVVM);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.nonceAsyncEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.identity, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
            params.user,
            params.identity,address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.flushCustomMetadata(
            params.user.Address,
            params.identity,address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(params.identity),
            0,
            "amount of custom metadata after flushCustomMetadata is incorrect"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance after flushCustomMetadata is incorrect"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "fisher balance after flushCustomMetadata is incorrect"
        );
    }

    function test__fuzz__flushCustomMetadata_staker(
        Input memory input
    ) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
                )
        );

        vm.assume(input.nonce != input.nonceAsyncEVVM);

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.nonceAsyncEVVM,
            signatureEVVM: ""
        });

        uint256 sizeOfCustomMetadata = nameService.getAmountOfCustomMetadata(
            params.identity
        );

        _addBalance(params.user, params.identity, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
            params.user,
            params.identity,address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.flushCustomMetadata(
            params.user.Address,
            params.identity,address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(params.identity),
            0,
            "amount of custom metadata after flushCustomMetadata is incorrect"
        );

        assertEq(
            core.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "user balance after flushCustomMetadata is incorrect"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * core.getRewardAmount()) * sizeOfCustomMetadata) +
                params.priorityFee,
            "fisher balance after flushCustomMetadata is incorrect"
        );
    }
}
