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

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/nameService/lib/ErrorsLib.sol";
import {
    ErrorsLib as EvvmErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";

contract unitTestRevert_NameService_flushUsername is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101,
            20202
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>1",
            11,
            11,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>2",
            22,
            22,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>3",
            33,
            33,
            true
        );
    }

    function addBalance(
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

    /**
     * Function to test:
     * bSigAt[variable]: bad signature at
     * bPaySigAt[variable]: bad payment signature at
     * some denominations on test can be explicit expleined
     */

    /*
    function test__unit_correct__flushUsername__bSigAt() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService.getIdentityBasicMetadata(
            "test"
        );

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    ////////////////////////////////////////////////////////////////////////////

    function test__unit_correct__flushUsername__() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService.getIdentityBasicMetadata(
            "test"
        );

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
    */

    function test__unit_correct__flushUsername__bSigAtSigner() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bSigAtUsername() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "user",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bSigAtNonceNameService()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                777
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtSigner() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtToAddress() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtToIdentity() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "nameservices",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtTokenAddress()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                ETHER_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtAmount() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                7,
                totalPriorityFeeAmount,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtPriorityFee()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                7,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtNonceEVVM() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                7,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtPriorityFlag()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                false,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__bPaySigAtExecutor() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                "test",
                110010011
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalAmountFlush,
                totalPriorityFeeAmount,
                1001,
                true,
                address(0)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__nonceAlreadyUsed() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                11,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            11,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__userIsNotOwner() external {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                110010011,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__userTryToFlushAfterExpire()
        external
    {
        skip(400 days);

        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__identityIsNotAUsername()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "notuser",
            1,
            99999999999999999999999999999999999
        );
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("notuser", uint256(1)))
                )
            ),
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(abi.encodePacked("notuser", uint256(1)))
                    )
                ),
                110010011,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(abi.encodePacked("notuser", uint256(1)))
                    )
                )
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("notuser", uint256(1)))
                )
            ),
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(abi.encodePacked("notuser", uint256(1)))
                    )
                )
            );

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_correct__flushUsername__userHasNotEnoughBalance()
        external
    {
        uint256 totalAmountFlush = 0;
        uint256 totalPriorityFeeAmount = 0;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                1001,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, userBefore);
        assertEq(expireDate, expireDateBefore);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
}
