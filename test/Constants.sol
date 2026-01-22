// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title EvvmStorage
 * @author jistro.eth
 * @dev Storage layout contract for EVVM proxy pattern implementation.
 *      This contract inherits all structures from EvvmStructs and
 *      defines the storage layout that will be used by the proxy pattern.
 *
 * @notice This contract should not be deployed directly, it's meant to be
 *         inherited by the implementation contracts to ensure they maintain
 *         the same storage layout.
 */
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/P2PSwapStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {
    StakingServiceUtils
} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";
import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";

abstract contract Constants is Test {
    Staking staking;
    Evvm evvm;
    Estimator estimator;
    NameService nameService;
    Treasury treasury;
    P2PSwap p2pSwap;

    bytes32 constant DEPOSIT_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(2));

    address constant PRINCIPAL_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;

    /*
        | ACCOUNT       |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  | 
        | ADMIN         |  X  |     |     |     |     |     |     |     |
        | Common users  |     |  X  |  X  |  X  |     |     |     |     |
        | Staker        |     |     |     |  X  |  X  |     |     |     |
        | Golden        |     |     |     |     |     |  X  |     |     |
        | Activator     |     |     |     |     |     |     |  X  |     |
        
        The 8th user is used as a WILDCARD
    */

    struct AccountData {
        address Address;
        uint256 PrivateKey;
    }

    AccountData ACCOUNT1 =
        AccountData({
            Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            PrivateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });

    AccountData ACCOUNT2 =
        AccountData({
            Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            PrivateKey: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        });

    AccountData ACCOUNT3 =
        AccountData({
            Address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            PrivateKey: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
        });

    AccountData ACCOUNT4 =
        AccountData({
            Address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            PrivateKey: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
        });

    AccountData ACCOUNT5 =
        AccountData({
            Address: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            PrivateKey: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
        });

    AccountData ACCOUNT6 =
        AccountData({
            Address: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            PrivateKey: 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
        });

    AccountData ACCOUNT7 =
        AccountData({
            Address: 0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            PrivateKey: 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
        });

    AccountData ACCOUNT8 =
        AccountData({
            Address: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            PrivateKey: 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        });

    AccountData ADMIN =
        AccountData({
            Address: ACCOUNT1.Address,
            PrivateKey: ACCOUNT1.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_1 =
        AccountData({
            Address: ACCOUNT2.Address,
            PrivateKey: ACCOUNT2.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_2 =
        AccountData({
            Address: ACCOUNT3.Address,
            PrivateKey: ACCOUNT3.PrivateKey
        });

    AccountData COMMON_USER_STAKER =
        AccountData({
            Address: ACCOUNT4.Address,
            PrivateKey: ACCOUNT4.PrivateKey
        });

    // this should be apllied only on sMATE and estimator tests
    AccountData STAKER =
        AccountData({
            Address: ACCOUNT5.Address,
            PrivateKey: ACCOUNT5.PrivateKey
        });

    AccountData GOLDEN_STAKER =
        AccountData({
            Address: ACCOUNT6.Address,
            PrivateKey: ACCOUNT6.PrivateKey
        });

    AccountData ACTIVATOR =
        AccountData({
            Address: ACCOUNT7.Address,
            PrivateKey: ACCOUNT7.PrivateKey
        });

    AccountData WILDCARD_USER =
        AccountData({
            Address: ACCOUNT8.Address,
            PrivateKey: ACCOUNT8.PrivateKey
        });

    function setUp() public virtual {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        evvm = new Evvm(
            ADMIN.Address,
            address(staking),
            EvvmStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 777,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );
        estimator = new Estimator(
            ACTIVATOR.Address,
            address(evvm),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(address(evvm), ADMIN.Address);

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));
        treasury = new Treasury(address(evvm));
        evvm._setupNameServiceAndTreasuryAddress(
            address(nameService),
            address(treasury)
        );

        p2pSwap = new P2PSwap(address(evvm), address(staking), ADMIN.Address);
        evvm.setPointStaker(address(p2pSwap), 0x01);

        if (address(p2pSwap) == address(0)) revert();

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        executeBeforeSetUp();
    }

    function executeBeforeSetUp() internal virtual {}

    function _execute_makeSignaturePay(
        AccountData memory user,
        address toAddress,
        string memory toIdentity,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor
    ) internal virtual returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                toAddress,
                toIdentity,
                tokenAddress,
                amount,
                priorityFee,
                nonce,
                priorityFlag,
                executor
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function _execute_makePay(
        AccountData memory user,
        address toAddress,
        string memory toIdentity,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor,
        AccountData memory fisher
    ) internal virtual {
        bytes memory signature = _execute_makeSignaturePay(
            user,
            toAddress,
            toIdentity,
            tokenAddress,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            executor
        );

        vm.startPrank(fisher.Address);
        evvm.pay(
            user.Address,
            toAddress,
            toIdentity,
            tokenAddress,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            executor,
            signature
        );
        vm.stopPrank();
    }

    function _execute_makeDispersePaySignature(
        AccountData memory user,
        EvvmStructs.DispersePayMetadata[] memory toData,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor
    ) internal virtual returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispersePay(
                evvm.getEvvmID(),
                sha256(abi.encode(toData)),
                tokenAddress,
                amount,
                priorityFee,
                nonce,
                priorityFlag,
                executor
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function _execute_makePreRegistrationUsernameSignature(
        AccountData memory user,
        string memory username,
        uint256 clowNumber,
        uint256 nonceNameService,
        uint256 priorityFeeAmount,
        uint256 nonceEVVM,
        bool priorityEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                evvm.getEvvmID(),
                keccak256(abi.encodePacked(username, clowNumber)),
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFeeAmount > 0
            ? _execute_makeSignaturePay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFeeAmount,
                nonceEVVM,
                priorityEVVM,
                address(nameService)
            )
            : bytes(hex"");
    }

    function _execute_makePreRegistrationUsername(
        AccountData memory user,
        string memory username,
        uint256 clowNumber,
        uint256 nonceNameService
    ) internal virtual {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                evvm.getEvvmID(),
                keccak256(abi.encodePacked(username, clowNumber)),
                nonceNameService
            )
        );

        nameService.preRegistrationUsername(
            user.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            Erc191TestBuilder.buildERC191Signature(v, r, s),
            0,
            0,
            false,
            hex""
        );
    }

    function _execute_makeRegistrationUsernameSignatures(
        AccountData memory user,
        string memory username,
        uint256 clowNumber,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                evvm.getEvvmID(),
                username,
                clowNumber,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                nameService.getPriceOfRegistration(username),
                priorityFeeAmountEVVM,
                nonceEVVM,
                priorityFlagEVVM,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeRegistrationUsername(
        AccountData memory user,
        string memory username,
        uint256 clowNumber,
        uint256 nonceNameServicePreRegister,
        uint256 nonceNameServiceRegister
    ) internal virtual {
        _execute_makePreRegistrationUsername(
            user,
            username,
            clowNumber,
            nonceNameServicePreRegister
        );

        skip(30 minutes);

        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username)
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                user,
                username,
                clowNumber,
                nonceNameServiceRegister,
                0,
                evvm.getNextCurrentSyncNonce(user.Address),
                false
            );

        nameService.registrationUsername(
            user.Address,
            username,
            clowNumber,
            nonceNameServiceRegister,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
    }

    function _execute_makeMakeOfferSignatures(
        AccountData memory user,
        string memory usernameToMakeOffer,
        uint256 expireDate,
        uint256 amountToOffer,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                usernameToMakeOffer,
                expireDate,
                amountToOffer,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            amountToOffer,
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeMakeOffer(
        AccountData memory user,
        string memory usernameToMakeOffer,
        uint256 expireDate,
        uint256 amountToOffer,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM,
        AccountData memory fisher
    ) internal virtual returns (uint256 offerID) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            amountToOffer + priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                user,
                usernameToMakeOffer,
                expireDate,
                amountToOffer,
                nonceNameService,
                priorityFeeAmountEVVM,
                nonceEVVM,
                priorityFlagEVVM
            );

        vm.startPrank(fisher.Address);
        offerID = nameService.makeOffer(
            user.Address,
            usernameToMakeOffer,
            expireDate,
            amountToOffer,
            nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );
        vm.stopPrank();
    }

    function _execute_makeWithdrawOfferSignatures(
        AccountData memory user,
        string memory usernameToFindOffer,
        uint256 index,
        uint256 nonceNameService,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                evvm.getEvvmID(),
                usernameToFindOffer,
                index,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFee > 0
            ? _execute_makeSignaturePay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFee,
                nonceEVVM,
                priorityFlagEVVM,
                address(nameService)
            )
            : bytes(hex"");
    }

    function _execute_makeAcceptOfferSignatures(
        AccountData memory user,
        string memory usernameToFindOffer,
        uint256 index,
        uint256 nonceNameService,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                usernameToFindOffer,
                index,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFee > 0
            ? _execute_makeSignaturePay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFee,
                nonceEVVM,
                priorityFlagEVVM,
                address(nameService)
            )
            : bytes(hex"");
    }

    function _execute_makeRenewUsernameSignatures(
        AccountData memory user,
        string memory usernameToRenew,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                usernameToRenew,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.seePriceToRenew(usernameToRenew),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeRenewUsername(
        AccountData memory user,
        string memory usernameToRenew,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM,
        AccountData memory fisher
    ) internal virtual {
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                user,
                usernameToRenew,
                nonceNameService,
                priorityFeeAmountEVVM,
                nonceEVVM,
                priorityFlagEVVM
            );

        vm.startPrank(fisher.Address);

        nameService.renewUsername(
            user.Address,
            usernameToRenew,
            nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function _execute_makeAddCustomMetadataSignatures(
        AccountData memory user,
        string memory username,
        string memory customMetadata,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                evvm.getEvvmID(),
                username,
                customMetadata,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata(),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeAddCustomMetadata(
        AccountData memory user,
        string memory username,
        string memory customMetadata,
        uint256 nonceNameService,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    ) internal virtual {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata()
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                user,
                username,
                customMetadata,
                nonceNameService,
                0,
                nonceEVVM,
                priorityFlagEVVM
            );

        nameService.addCustomMetadata(
            user.Address,
            username,
            customMetadata,
            nonceNameService,
            signatureNameService,
            0,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );
    }

    function _execute_makeRemoveCustomMetadataSignatures(
        AccountData memory user,
        string memory username,
        uint256 indexCustomMetadata,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                username,
                indexCustomMetadata,
                nonceNameService
            )
        );

        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata(),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeFlushCustomMetadataSignatures(
        AccountData memory user,
        string memory username,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                evvm.getEvvmID(),
                username,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(username),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeFlushUsernameSignatures(
        AccountData memory user,
        string memory username,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                evvm.getEvvmID(),
                username,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername(username),
            priorityFeeAmountEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(nameService)
        );
    }

    function _execute_makeGoldenStakingSignature(
        bool isStaking,
        uint256 amount
    ) internal virtual returns (bytes memory signatureEVVM) {
        signatureEVVM = isStaking
            ? _execute_makeSignaturePay(
                GOLDEN_STAKER,
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                (staking.priceOfStaking() * amount),
                0,
                evvm.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
                false,
                address(staking)
            )
            : bytes(hex"");
    }

    function _execute_makeGoldenStaking(
        bool isStaking,
        uint256 amount
    ) internal virtual {
        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(
            isStaking,
            amount,
            _execute_makeGoldenStakingSignature(isStaking, amount)
        );

        vm.stopPrank();
    }

    function _execute_makePresaleStakingSignature(
        AccountData memory user,
        bool isStaking,
        uint256 nonceStaking,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureStaking, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                isStaking,
                1,
                nonceStaking
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking(),
            priorityFee,
            nonceEVVM,
            priorityFlagEVVM,
            address(staking)
        );
    }

    function _execute_makePresaleStaking(
        AccountData memory user,
        bool isStaking,
        uint256 nonceStaking,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlagEVVM,
        AccountData memory fisher
    ) internal virtual {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking() + priorityFee
        );

        (
            bytes memory signatureStaking,
            bytes memory signatureEVVM
        ) = _execute_makePresaleStakingSignature(
                user,
                isStaking,
                nonceStaking,
                priorityFee,
                nonceEVVM,
                priorityFlagEVVM
            );

        vm.startPrank(fisher.Address);

        staking.presaleStaking(
            user.Address,
            isStaking,
            nonceStaking,
            signatureStaking,
            priorityFee,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function _execute_makePublicStakingSignature(
        AccountData memory user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        uint256 priorityFeeEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        internal
        virtual
        returns (bytes memory signatureStaking, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                evvm.getEvvmID(),
                isStaking,
                amountOfStaking,
                nonce
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);

        if (isStaking) {
            signatureEVVM = _execute_makeSignaturePay(
                user,
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                staking.priceOfStaking() * amountOfStaking,
                priorityFeeEVVM,
                nonceEVVM,
                priorityFlagEVVM,
                address(staking)
            );
        } else {
            signatureEVVM = _execute_makeSignaturePay(
            user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            0,
            priorityFeeEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            address(staking)
        );
        }
    }

    function _execute_makePublicStaking(
        AccountData memory user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        uint256 priorityFeeEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM,
        AccountData memory fisher
    ) internal virtual {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            staking.priceOfStaking() * amountOfStaking + priorityFeeEVVM
        );

        (
            bytes memory signatureStaking,
            bytes memory signatureEVVM
        ) = _execute_makePublicStakingSignature(
                user,
                isStaking,
                amountOfStaking,
                nonce,
                priorityFeeEVVM,
                nonceEVVM,
                priorityFlagEVVM
            );

        vm.startPrank(fisher.Address);

        staking.publicStaking(
            user.Address,
            isStaking,
            amountOfStaking,
            nonce,
            signatureStaking,
            priorityFeeEVVM,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();
    }
}

contract MockContractToStake is StakingServiceUtils {
    constructor(address stakingAddress) StakingServiceUtils(stakingAddress) {}

    function stake(uint256 amountToStake) public {
        _makeStakeService(amountToStake);
    }

    function stakeJustInPartOne(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
    }

    function stakeJustInPartTwo(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStake
        );
    }

    function stakeJustConfirm() public {
        staking.confirmServiceStaking();
    }

    function stakeWithTokenAddress(
        uint256 amountToStake,
        address tokenAddress
    ) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            tokenAddress,
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    function stakeWithAmountDiscrepancy(
        uint256 amountToStakeDiscrepancy,
        uint256 amountToStake
    ) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStakeDiscrepancy
        );
        staking.confirmServiceStaking();
    }

    function unstake(uint256 amountToUnstake) public {
        _makeUnstakeService(amountToUnstake);
    }

    function getBackMate(address user) public {
        IEvvm(staking.getEvvmAddress()).caPay(
            user,
            0x0000000000000000000000000000000000000001,
            IEvvm(staking.getEvvmAddress()).getBalance(
                address(this),
                0x0000000000000000000000000000000000000001
            )
        );
    }
}

contract TestERC20 is ERC20 {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function name() public view override returns (string memory) {
        return "TestToken";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return "TTK";
    }
}

contract HelperCa {
    Evvm evvm;

    constructor(address _evvm) {
        evvm = Evvm(_evvm);
    }

    function makeCaPay(address user, address token, uint256 amount) public {
        evvm.caPay(user, token, amount);
    }

    function makeDisperseCaPay(
        EvvmStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 totalAmount
    ) public {
        evvm.disperseCaPay(toData, token, totalAmount);
    }
}

interface ITartarusV1 {
    function burnToken(address user, address token, uint256 amount) external;
}

contract TartarusV1 is EvvmStorage {
    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;
    }
}

interface ITartarusV2 {
    function burnToken(address user, address token, uint256 amount) external;

    function fullTransfer(address from, address to, address token) external;
}

contract TartarusV2 is EvvmStorage {
    function fullTransfer(address from, address to, address token) external {
        balances[to][token] += balances[from][token];
        balances[from][token] -= balances[from][token];
    }
}

interface ITartarusV3 {
    function burnToken(address user, address token, uint256 amount) external;

    function getCounter() external view returns (uint256);
}

// Primero definimos la interfaz
interface ICounter {
    function increment() external;

    function getCounter() external view returns (uint256);
}

contract TartarusV3 is EvvmStorage {
    address public immutable counterAddress;

    constructor(address _counterAddress) {
        counterAddress = _counterAddress;
    }

    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;

        ICounter(counterAddress).increment();
    }

    function getCounter() external view returns (uint256) {
        // Usamos la interfaz para la llamada
        (bool success, bytes memory data) = counterAddress.staticcall(
            abi.encodeWithSignature("getCounter()")
        );
        if (!success) {
            revert();
        }
        return abi.decode(data, (uint256));
    }
}

contract CounterDummy {
    uint256 counterNum;

    function increment() external {
        counterNum++;
    }

    function getCounter() external view returns (uint256) {
        return counterNum;
    }
}
