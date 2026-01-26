// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**                                                                                                        
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄ 
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██   
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██   
                                                    
                                                    
                                                    
 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄          
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██            
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██                                                    
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract unitTestCorrect_NameService_flushCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string CUSTOM_METADATA_VALUE_1 = "test>1";
    string CUSTOM_METADATA_VALUE_2 = "test>2";
    string CUSTOM_METADATA_VALUE_3 = "test>3";

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
            nameService.getPriceToFlushCustomMetadata(
                usernameToFlushCustomMetadata
            ) + priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushCustomMetadata(
            usernameToFlushCustomMetadata
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_correct__flushCustomMetadata_noStaker_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
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

    function test__unit_correct__flushCustomMetadata_noStaker_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 1001,
            priorityEVVM: true,
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


    function test__unit_correct__flushCustomMetadata_noStaker_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
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

    function test__unit_correct__flushCustomMetadata_noStaker_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 1001,
            priorityEVVM: true,
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

    function test__unit_correct__flushCustomMetadata_staker_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
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

    function test__unit_correct__flushCustomMetadata_staker_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 1001,
            priorityEVVM: true,
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


    function test__unit_correct__flushCustomMetadata_staker_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            priorityEVVM: false,
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

    function test__unit_correct__flushCustomMetadata_staker_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 1001,
            priorityEVVM: true,
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
