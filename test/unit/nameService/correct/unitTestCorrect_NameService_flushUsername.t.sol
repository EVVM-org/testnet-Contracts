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
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

contract unitTestCorrect_NameService_flushUsername is Test, Constants {
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
            444,
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

        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            )
        );
        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6
            )
        );
        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_3,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8
            )
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

    function test__unit_correct__flushUsername__noStaker_noPriorityFee()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 110010011,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 1001,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            params.username
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.flushUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(params.username);

        assertEq(user, address(0), "username owner should be flushed");
        assertEq(expirationDate, 0, "username expire date should be flushed");

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

    function test__unit_correct__flushUsername__noStaker_priorityFee()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 110010011,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 1001,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            params.username
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.flushUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(params.username);

        assertEq(user, address(0), "username owner should be flushed");
        assertEq(expirationDate, 0, "username expire date should be flushed");

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

    function test__unit_correct__flushUsername__staker_noPriorityFee()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 110010011,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 1001,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            params.username
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.flushUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(params.username);

        assertEq(user, address(0), "username owner should be flushed");
        assertEq(expirationDate, 0, "username expire date should be flushed");

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "username owner balance should be zeroed"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                params.priorityFee,
            "fisher staker balance should be increased correctly"
        );
    }

    function test__unit_correct__flushUsername__staker_priorityFee() external {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 110010011,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 1001,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_flushUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            params.username
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.flushUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(params.username);

        assertEq(user, address(0), "username owner should be flushed");
        assertEq(expirationDate, 0, "username expire date should be flushed");

        assertEq(
            evvm.getBalance(params.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "username owner balance should be zeroed"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                params.priorityFee,
            "fisher staker balance should be increased correctly"
        );
    }
}
