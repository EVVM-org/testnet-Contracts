// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestRevert_Staking_publicStaking is Test, Constants {

    
    
    
    

    function executeBeforeSetUp() internal override {

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();

        vm.stopPrank();
    }

    function giveMateToExecute(
        AccountData memory user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 totalOfMate, uint256 totalOfPriorityFee) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount) + priorityFee
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
        totalOfPriorityFee = priorityFee;
    }

    function getAmountOfRewardsPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    function makeSignature(
        AccountData memory signer,
        bool isStaking,
        uint256 amountOfSmate,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityEVVM,
        uint256 nonceSmate
    )
        private
        view
        returns (bytes memory signatureEVVM, bytes memory signatureStaking)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (isStaking) {
            (v, r, s) = vm.sign(
                signer.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    staking.priceOfStaking() * amountOfSmate,
                    priorityFee,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        } else {
            (v, r, s) = vm.sign(
                signer.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    priorityFee,
                    0,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        }

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            signer.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                isStaking,
                amountOfSmate,
                nonceSmate
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    /**
     * Function to test:
     * bPaySigAt[section]: incorrect payment signature // bad signature
     * bStakeSigAt[section]: incorrect stake signature // bad signature
     * wValAt[section]: wrong value
     * some denominations on test can be explicit expleined
     */

    function test__unit_revert__publicStaking__bPaySigAtSigned() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtToAddress() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    /*
     ! note: if staking in the future has a NameService identity, then rework
     !       this test
     */
    function test__unit_revert__publicStaking__bPaySigAtToIdentity() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "smate",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtToken() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                ETHER_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtAmount() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                777,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtPriorityFee() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                777,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtNonce() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                77,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtPriorityFlag() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                false,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bPaySigAtExecutor() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(evvm)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bStakeSigAtSigner() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bStakeSigAtIsStakingFlag()
        public
    {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                false,
                111,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bStakeSigAtAmount() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                true,
                777,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__bStakeSigAtNonce() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                1001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),true, 111, 777)
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__NonceAlreadyUsed() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            2,
            0 ether
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            1,
            totalOfPriorityFee,
            1001001,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            1001001,
            true,
            signatureEVVM
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            1,
            totalOfPriorityFee,
            2002002,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            2002002,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (totalOfMate / 2) + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__UserTryToFullUnstakeWithoutWaitTime()
        public
    {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            totalOfPriorityFee,
            1001001,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            1001001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            false,
            111,
            totalOfPriorityFee,
            2002002,
            true,
            2002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            111,
            2002,
            signatureStaking,
            totalOfPriorityFee,
            2002002,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }

    function test__unit_revert__publicStaking__notInTimeToRestake() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(5 days);
        skip(1 days);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            totalOfPriorityFee,
            1001001,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            1001001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        skip(staking.getSecondsToUnlockFullUnstaking());

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            false,
            111,
            totalOfPriorityFee,
            2002002,
            true,
            2002
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            111,
            2002,
            signatureStaking,
            totalOfPriorityFee,
            2002002,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            totalOfPriorityFee,
            3003003,
            true,
            3003
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            3003,
            signatureStaking,
            totalOfPriorityFee,
            3003003,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__UserTriesToUnstakeWithoutStaking()
        public
    {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            0,
            0 ether
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            false,
            111,
            totalOfPriorityFee,
            1001001,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            111,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            1001001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }

    function test__unit_revert__publicStaking__stakeWithoutFlagOnTrue() public {
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();

        vm.stopPrank();

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1,
            111,
            0 ether
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            COMMON_USER_NO_STAKER_1,
            true,
            111,
            totalOfPriorityFee,
            1001001,
            true,
            1001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        staking.publicStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            111,
            1001,
            signatureStaking,
            totalOfPriorityFee,
            1001001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }
}
