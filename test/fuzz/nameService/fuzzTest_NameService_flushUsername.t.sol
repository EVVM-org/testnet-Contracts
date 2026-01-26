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

contract fuzzTest_NameService_flushUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string CUSTOM_METADATA_VALUE_1 = "test>1";
    string CUSTOM_METADATA_VALUE_2 = "test>2";
    string CUSTOM_METADATA_VALUE_3 = "test>3";

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
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

        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            true
        );
        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            true
        );
        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_3,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9
            ),
            true
        );
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
            nameService.getPriceToFlushUsername(usernameToFlushCustomMetadata) +
                priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushUsername(
            usernameToFlushCustomMetadata
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    struct Input {
        uint256 nonceNameService;
        uint32 priorityFee;
        uint256 nonceAsyncEVVM;
        bool priorityEVVM;
    }

    function test__fuzz__flushUsername__noStaker(Input memory input) external {
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
            username: USERNAME,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: uint256(input.priorityFee),
            nonceEVVM: input.priorityEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
            params.user,
            params.username,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            params.username
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.flushUsername(
            params.user.Address,
            params.username,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(params.username);

        assertEq(user, address(0), "username owner should be flushed");
        assertEq(expireDate, 0, "username expire date should be flushed");

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "username owner balance should be zeroed"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                params.priorityFee,
            "fisher no staker balance should be increased correctly"
        );
    }
}
