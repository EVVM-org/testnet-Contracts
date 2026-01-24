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

contract unitTestCorrect_Staking_presaleStaking is Test, Constants {
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    function executeBeforeSetUp() internal override {
        /**
         *  @dev Because presale staking is disabled by default in 
                 testnet contracts, we need to enable it here
         */
        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPresaleStaking();
        skip(1 days);
        staking.confirmChangeAllowPresaleStaking();

        assertTrue(
            staking.getAllowPresaleStaking().flag,
            "presale staking was not enabled in setup"
        );

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();

        assertFalse(
            staking.getAllowPublicStaking().flag,
            "public staking was not disabled in setup"
        );

        ///@dev Adding a presale staker to be able to execute
        ///     presale staking tests
        staking.addPresaleStaker(USER.Address);
        vm.stopPrank();
    }

    function _addBalance(
        address user,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking()) + priorityFee
        );
        return (staking.priceOfStaking(), priorityFee);
    }

    struct Params {
        AccountData user;
        bool isStaking;
        uint256 nonceStake;
        uint256 _amountInPrincipal;
        bytes signatureStake;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityFlagEVVM;
        bytes signatureEVVM;
    }

    function test__unit_correct__presaleStaking__staking_noFisherStake_noPriorityfee()
        external
    {
        Params memory paramsSync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsAsync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsSync._amountInPrincipal, ) = _addBalance(
            paramsSync.user.Address,
            paramsSync.priorityFee
        );

        (
            paramsSync.signatureStake,
            paramsSync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsSync.user,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsSync.user.Address,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.signatureStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM,
            paramsSync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSync.user.Address)
            );
        historySync = staking.getAddressHistory(paramsSync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsSync.user.Address),
            "ERROR [payment sync execution] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [payment sync execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment sync execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [payment sync execution] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [payment sync execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [payment sync execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsAsync._amountInPrincipal, ) = _addBalance(
            paramsAsync.user.Address,
            paramsAsync.priorityFee
        );

        (
            paramsAsync.signatureStake,
            paramsAsync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsAsync.user,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsAsync.user.Address,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.signatureStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM,
            paramsAsync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsync.user.Address)
            );
        historyAsync = staking.getAddressHistory(paramsAsync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsAsync.user.Address),
            "ERROR [payment async execution] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [payment async execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment async execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [payment async execution] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [payment async execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [payment async execution] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_noFisherStake_priorityfee()
        external
    {
        Params memory paramsSync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsAsync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsSync._amountInPrincipal, ) = _addBalance(
            paramsSync.user.Address,
            paramsSync.priorityFee
        );

        (
            paramsSync.signatureStake,
            paramsSync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsSync.user,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsSync.user.Address,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.signatureStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM,
            paramsSync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSync.user.Address)
            );
        historySync = staking.getAddressHistory(paramsSync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsSync.user.Address),
            "ERROR [payment sync execution] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [payment sync execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment sync execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [payment sync execution] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [payment sync execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [payment sync execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsAsync._amountInPrincipal, ) = _addBalance(
            paramsAsync.user.Address,
            paramsAsync.priorityFee
        );

        (
            paramsAsync.signatureStake,
            paramsAsync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsAsync.user,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsAsync.user.Address,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.signatureStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM,
            paramsAsync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsync.user.Address)
            );
        historyAsync = staking.getAddressHistory(paramsAsync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsAsync.user.Address),
            "ERROR [payment async execution] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [payment async execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment async execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [payment async execution] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [payment async execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [payment async execution] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_fisherStake_noPriorityfee()
        external
    {
        Params memory paramsSync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsAsync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsSync._amountInPrincipal, ) = _addBalance(
            paramsSync.user.Address,
            paramsSync.priorityFee
        );

        (
            paramsSync.signatureStake,
            paramsSync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsSync.user,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            paramsSync.user.Address,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.signatureStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM,
            paramsSync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSync.user.Address)
            );
        historySync = staking.getAddressHistory(paramsSync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsSync.user.Address),
            "ERROR [payment sync execution] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [payment sync execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment sync execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [payment sync execution] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [payment sync execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + paramsSync.priorityFee,
            "ERROR [payment sync execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsAsync._amountInPrincipal, ) = _addBalance(
            paramsAsync.user.Address,
            paramsAsync.priorityFee
        );

        (
            paramsAsync.signatureStake,
            paramsAsync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsAsync.user,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            paramsAsync.user.Address,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.signatureStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM,
            paramsAsync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsync.user.Address)
            );
        historyAsync = staking.getAddressHistory(paramsAsync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsAsync.user.Address),
            "ERROR [payment async execution] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [payment async execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment async execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [payment async execution] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [payment async execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                paramsAsync.priorityFee +
                paramsSync.priorityFee,
            "ERROR [payment async execution] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_fisherStake_priorityfee()
        external
    {
        Params memory paramsSync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsAsync = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsSync._amountInPrincipal, ) = _addBalance(
            paramsSync.user.Address,
            paramsSync.priorityFee
        );

        (
            paramsSync.signatureStake,
            paramsSync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsSync.user,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            paramsSync.user.Address,
            paramsSync.isStaking,
            paramsSync.nonceStake,
            paramsSync.signatureStake,
            paramsSync.priorityFee,
            paramsSync.nonceEVVM,
            paramsSync.priorityFlagEVVM,
            paramsSync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historySync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsSync.user.Address)
            );
        historySync = staking.getAddressHistory(paramsSync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsSync.user.Address),
            "ERROR [payment sync execution] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [payment sync execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment sync execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [payment sync execution] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [payment sync execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + paramsSync.priorityFee,
            "ERROR [payment sync execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsAsync._amountInPrincipal, ) = _addBalance(
            paramsAsync.user.Address,
            paramsAsync.priorityFee
        );

        (
            paramsAsync.signatureStake,
            paramsAsync.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsAsync.user,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            paramsAsync.user.Address,
            paramsAsync.isStaking,
            paramsAsync.nonceStake,
            paramsAsync.signatureStake,
            paramsAsync.priorityFee,
            paramsAsync.nonceEVVM,
            paramsAsync.priorityFlagEVVM,
            paramsAsync.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyAsync = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsAsync.user.Address)
            );
        historyAsync = staking.getAddressHistory(paramsAsync.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsAsync.user.Address),
            "ERROR [payment async execution] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [payment async execution] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [payment async execution] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [payment async execution] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [payment async execution] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                paramsAsync.priorityFee +
                paramsSync.priorityFee,
            "ERROR [payment async execution] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__unstakingAndFullUnstaking_noFisherStake()
        external
    {
        for (uint256 i = 0; i < 2; i++) {
            _addBalance(USER.Address, 0);
            _execute_makePresaleStaking(
                USER,
                true,
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ) + i,
                0,
                evvm.getNextCurrentSyncNonce(USER.Address),
                false,
                GOLDEN_STAKER
            );
        }

        Params memory paramsUnstake = Params({
            user: USER,
            isStaking: false,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER.Address),
            priorityFlagEVVM: false,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsFullUnstake = Params({
            user: USER,
            isStaking: false,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing unstake ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsUnstake._amountInPrincipal, ) = _addBalance(
            paramsUnstake.user.Address,
            paramsUnstake.priorityFee
        );

        (
            paramsUnstake.signatureStake,
            paramsUnstake.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsUnstake.user,
            paramsUnstake.isStaking,
            paramsUnstake.nonceStake,
            paramsUnstake.priorityFee,
            paramsUnstake.nonceEVVM,
            paramsUnstake.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsUnstake.user.Address,
            paramsUnstake.isStaking,
            paramsUnstake.nonceStake,
            paramsUnstake.signatureStake,
            paramsUnstake.priorityFee,
            paramsUnstake.nonceEVVM,
            paramsUnstake.priorityFlagEVVM,
            paramsUnstake.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyUnstake = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsUnstake.user.Address)
            );
        historyUnstake = staking.getAddressHistory(paramsUnstake.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsUnstake.user.Address),
            "ERROR [unstake execution] : presale user must still point as staker"
        );

        assertEq(
            historyUnstake[2].timestamp,
            block.timestamp,
            "ERROR [unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "ERROR [unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].amount,
            1,
            "ERROR [unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].totalStaked,
            1,
            "ERROR [unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [unstake execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing full unstake ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        skip(staking.getSecondsToUnlockFullUnstaking());

        (paramsFullUnstake._amountInPrincipal, ) = _addBalance(
            paramsFullUnstake.user.Address,
            paramsFullUnstake.priorityFee
        );

        (
            paramsFullUnstake.signatureStake,
            paramsFullUnstake.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            paramsFullUnstake.user,
            paramsFullUnstake.isStaking,
            paramsFullUnstake.nonceStake,
            paramsFullUnstake.priorityFee,
            paramsFullUnstake.nonceEVVM,
            paramsFullUnstake.priorityFlagEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsFullUnstake.user.Address,
            paramsFullUnstake.isStaking,
            paramsFullUnstake.nonceStake,
            paramsFullUnstake.signatureStake,
            paramsFullUnstake.priorityFee,
            paramsFullUnstake.nonceEVVM,
            paramsFullUnstake.priorityFlagEVVM,
            paramsFullUnstake.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyFullUnstake = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsFullUnstake.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(
            paramsFullUnstake.user.Address
        );

        assertFalse(
            evvm.isAddressStaker(paramsFullUnstake.user.Address),
            "ERROR [full unstake execution] : presale user must not point as staker anymore"
        );

        assertEq(
            historyFullUnstake[3].timestamp,
            block.timestamp,
            "ERROR [full unstake execution] : timestamp in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "ERROR [full unstake execution] : transactionType in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].amount,
            1,
            "ERROR [full unstake execution] : amount in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].totalStaked,
            0,
            "ERROR [full unstake execution] : totalStaked in history [3] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [full unstake execution]  : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__stakeAfterFullUnstaking_noFisherStake()
        external
    {
        _addBalance(USER.Address, 0);
        _execute_makePresaleStaking(
            USER,
            true,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePresaleStaking(
            USER,
            false,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );


        Params memory params = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        skip(staking.getSecondsToUnlockFullUnstaking());

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        skip(staking.getSecondsToUnlockStaking());

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyFullUnstake = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(
            params.user.Address
        );

        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "ERROR [stake after full unstake execution] : presale user must be pointer as staker"
        );

        assertEq(
            historyFullUnstake[2].timestamp,
            block.timestamp,
            "ERROR [stake after full unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [stake after full unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].amount,
            1,
            "ERROR [stake after full unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].totalStaked,
            1,
            "ERROR [stake after full unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [stake after full unstake execution]  : balance of fisher after staking is not correct"
        );
    }


    function test__unit_correct__presaleStaking__stakeAfterFullUnstaking_fisherStake()
        external
    {
        _addBalance(USER.Address, 0);
        _execute_makePresaleStaking(
            USER,
            true,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _execute_makePresaleStaking(
            USER,
            false,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            0,
            evvm.getNextCurrentSyncNonce(USER.Address),
            false,
            GOLDEN_STAKER
        );


        Params memory params = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityFlagEVVM: true,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        skip(staking.getSecondsToUnlockFullUnstaking());

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _execute_makePresaleStakingSignature(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM
        );

        skip(staking.getSecondsToUnlockStaking());

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityFlagEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        Staking.HistoryMetadata[]
            memory historyFullUnstake = new Staking.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(
            params.user.Address
        );

        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "ERROR [stake after full unstake execution] : presale user must be pointer as staker"
        );

        assertEq(
            historyFullUnstake[2].timestamp,
            block.timestamp,
            "ERROR [stake after full unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [stake after full unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].amount,
            1,
            "ERROR [stake after full unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].totalStaked,
            1,
            "ERROR [stake after full unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFee,
            "ERROR [stake after full unstake execution]  : balance of fisher after staking is not correct"
        );
    }
}
