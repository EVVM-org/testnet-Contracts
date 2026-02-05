// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 _____                                                       
/__   \_ __ ___  __ _ ___ _   _ _ __ _   _                   
  / /\| '__/ _ \/ _` / __| | | | '__| | | |                  
 / /  | | |  __| (_| \__ | |_| | |  | |_| |                  
 \/   |_|  \___|\__,_|___/\__,_|_|   \__, |                  
                                     |___/                   
   ___ _           _       __ _        _   _                 
  / __| |__   __ _(_)_ __ / _| |_ __ _| |_(_) ___  _ __      
 / /  | '_ \ / _` | | '_ \\ \| __/ _` | __| |/ _ \| '_ \     
/ /___| | | | (_| | | | | _\ | || (_| | |_| | (_) | | | |    
\____/|_| |_|\__,_|_|_| |_\__/\__\__,_|\__|_|\___/|_| |_|    
                                                             
                                                             
                                                             
 _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ 
|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
                                                             
    __  __           __          __          _     
   / / / ____  _____/ /_   _____/ /_  ____ _(_____ 
  / /_/ / __ \/ ___/ __/  / ___/ __ \/ __ `/ / __ \
 / __  / /_/ (__  / /_   / /__/ / / / /_/ / / / / /
/_/ /_/\____/____/\__/   \___/_/ /_/\__,_/_/_/ /_/ 
                                                   
 * @title Treasury Cross-Chain Host Station Contract
 * @author Mate labs
 */

import {IERC20} from "@evvm/testnet-contracts/library/primitives/IERC20.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    CrossChainTreasuryError as Error
} from "@evvm/testnet-contracts/library/errors/CrossChainTreasuryError.sol";
import {
    HostChainStationStructs
} from "@evvm/testnet-contracts/library/structs/HostChainStationStructs.sol";

import {
    SignatureUtils
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/SignatureUtils.sol";
import {
    PayloadUtils
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/PayloadUtils.sol";

import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

import {
    MessagingParams,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {
    OApp,
    Origin,
    MessagingFee
} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {
    OAppOptionsType3
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {
    OptionsBuilder
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {
    AxelarExecutable
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {
    IAxelarGasService
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {
    IInterchainGasEstimation
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainGasEstimation.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract TreasuryHostChainStation is
    HostChainStationStructs,
    OApp,
    OAppOptionsType3,
    AxelarExecutable
{
    /// @notice EVVM core contract for balance operations
    /// @dev Used to integrate with EVVM's balance management and token operations
    Evvm evvm;

    /// @notice Admin address management with time-delayed proposals
    /// @dev Stores current admin, proposed admin, and acceptance timestamp
    AddressTypeProposal admin;

    /// @notice Fisher executor address management with time-delayed proposals
    /// @dev Fisher executor can process cross-chain bridge transactions
    AddressTypeProposal fisherExecutor;

    /// @notice Hyperlane protocol configuration for cross-chain messaging
    /// @dev Contains domain ID, external chain address, and mailbox contract address
    HyperlaneConfig hyperlane;

    /// @notice LayerZero protocol configuration for omnichain messaging
    /// @dev Contains endpoint ID, external chain address, and endpoint contract address
    LayerZeroConfig layerZero;

    /// @notice Axelar protocol configuration for cross-chain communication
    /// @dev Contains chain name, external chain address, gas service, and gateway addresses
    AxelarConfig axelar;

    /// @notice Pending proposal for changing external chain addresses across all protocols
    /// @dev Used for coordinated updates to external chain addresses with time delay
    ChangeExternalChainAddressParams externalChainAddressChangeProposal;

    /// @notice Tracks the next nonce for Fisher bridge operations per user address
    /// @dev Prevents replay attacks in Fisher bridge transactions
    mapping(address => uint256) nextFisherExecutionNonce;

    /// @notice LayerZero execution options with gas limit configuration
    /// @dev Pre-built options for LayerZero message execution (200k gas limit)
    bytes options =
        OptionsBuilder.addExecutorLzReceiveOption(
            OptionsBuilder.newOptions(),
            200_000,
            0
        );

    /// @notice One-time fuse for setting initial external chain addresses
    /// @dev Prevents multiple calls to _setExternalChainAddress after initial setup
    bytes1 fuseSetExternalChainAddress = 0x01;

    /// @notice Emitted when Fisher bridge sends tokens from host to external chain
    /// @param from Original sender address on host chain
    /// @param addressToReceive Recipient address on external chain
    /// @param tokenAddress Token contract address (address(0) for ETH)
    /// @param priorityFee Fee paid for priority processing
    /// @param amount Amount of tokens transferred
    /// @param nonce Sequential nonce for the Fisher bridge operation
    event FisherBridgeSend(
        address indexed from,
        address indexed addressToReceive,
        address indexed tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce
    );

    /// @notice Restricts function access to the current admin only
    /// @dev Validates caller against admin.current address
    modifier onlyAdmin() {
        if (msg.sender != admin.current) {
            revert();
        }
        _;
    }

    /// @notice Restricts function access to the current Fisher executor only
    /// @dev Validates caller against fisherExecutor.current address for bridge operations
    modifier onlyFisherExecutor() {
        if (msg.sender != fisherExecutor.current) {
            revert();
        }
        _;
    }

    /// @notice Initializes the Host Chain Station with EVVM integration and cross-chain protocols
    /// @dev Sets up Hyperlane, LayerZero, and Axelar configurations for multi-protocol support
    /// @param _evvmAddress Address of the EVVM core contract for balance operations
    /// @param _admin Initial admin address with full administrative privileges
    /// @param _crosschainConfig Configuration struct containing all cross-chain protocol settings
    constructor(
        address _evvmAddress,
        address _admin,
        CrosschainConfig memory _crosschainConfig
    )
        OApp(_crosschainConfig.layerZero.endpointAddress, _admin)
        Ownable(_admin)
        AxelarExecutable(_crosschainConfig.axelar.gatewayAddress)
    {
        evvm = Evvm(_evvmAddress);

        admin = AddressTypeProposal({
            current: _admin,
            proposal: address(0),
            timeToAccept: 0
        });
        hyperlane = HyperlaneConfig({
            externalChainStationDomainId: _crosschainConfig
                .hyperlane
                .externalChainStationDomainId,
            externalChainStationAddress: "",
            mailboxAddress: _crosschainConfig.hyperlane.mailboxAddress
        });
        layerZero = LayerZeroConfig({
            externalChainStationEid: _crosschainConfig
                .layerZero
                .externalChainStationEid,
            externalChainStationAddress: "",
            endpointAddress: _crosschainConfig.layerZero.endpointAddress
        });
        axelar = AxelarConfig({
            externalChainStationChainName: _crosschainConfig
                .axelar
                .externalChainStationChainName,
            externalChainStationAddress: "",
            gasServiceAddress: _crosschainConfig.axelar.gasServiceAddress,
            gatewayAddress: _crosschainConfig.axelar.gatewayAddress
        });
    }

    /// @notice One-time setup of external chain station address across all protocols
    /// @dev Can only be called once (protected by fuseSetExternalChainAddress)
    /// @param externalChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param externalChainStationAddressString String representation for Axelar protocol
    function _setExternalChainAddress(
        address externalChainStationAddress,
        string memory externalChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetExternalChainAddress != 0x01) revert();

        hyperlane.externalChainStationAddress = bytes32(
            uint256(uint160(externalChainStationAddress))
        );
        layerZero.externalChainStationAddress = bytes32(
            uint256(uint160(externalChainStationAddress))
        );
        axelar.externalChainStationAddress = externalChainStationAddressString;
        _setPeer(
            layerZero.externalChainStationEid,
            layerZero.externalChainStationAddress
        );

        fuseSetExternalChainAddress = 0x00;
    }

    /// @notice Withdraws tokens from EVVM balance and sends to external chain via selected protocol
    /// @dev Validates balance, deducts from EVVM, and bridges via Hyperlane/LayerZero/Axelar
    /// @param toAddress Recipient address on the external chain
    /// @param token Token contract address (cannot be Principal Token)
    /// @param amount Amount to withdraw and send to external chain
    /// @param protocolToExecute Protocol selector: 0x01=Hyperlane, 0x02=LayerZero, 0x03=Axelar
    function withdraw(
        address toAddress,
        address token,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        if (token == evvm.getEvvmMetadata().principalTokenAddress)
            revert Error.PrincipalTokenIsNotWithdrawable();

        if (evvm.getBalance(msg.sender, token) < amount)
            revert Error.InsufficientBalance();

        executerEVVM(false, msg.sender, token, amount);

        bytes memory payload = PayloadUtils.encodePayload(
            token,
            toAddress,
            amount
        );

        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, token, amount);
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.externalChainStationDomainId,
                hyperlane.externalChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            _lzSend(
                layerZero.externalChainStationEid,
                payload,
                options,
                MessagingFee(msg.value, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value}(
                address(this),
                axelar.externalChainStationChainName,
                axelar.externalChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.externalChainStationChainName,
                axelar.externalChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    /// @notice Receives Fisher bridge transactions from external chain and credits EVVM balances
    /// @dev Verifies signature, increments nonce, and adds balance to recipient and executor
    /// @param from Original sender address from external chain
    /// @param addressToReceive Recipient address on this host chain
    /// @param tokenAddress Token contract address (address(0) for ETH)
    /// @param priorityFee Fee amount paid to Fisher executor
    /// @param amount Amount of tokens being received
    /// @param signature ECDSA signature proving transaction authorization
    function fisherBridgeReceive(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                evvm.getEvvmID(),
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) revert Error.InvalidSignature();

        nextFisherExecutionNonce[from]++;

        executerEVVM(true, addressToReceive, tokenAddress, amount);

        if (priorityFee > 0)
            executerEVVM(true, msg.sender, tokenAddress, priorityFee);
    }

    /// @notice Processes Fisher bridge token transfers from host to external chain
    /// @dev Validates balance and signature, deducts from sender, pays executor fee
    /// @param from Sender address initiating the bridge transaction
    /// @param addressToReceive Recipient address on the external chain
    /// @param tokenAddress Token contract address (cannot be Principal Token)
    /// @param priorityFee Fee amount paid to Fisher executor
    /// @param amount Amount of tokens to bridge to external chain
    /// @param signature ECDSA signature proving transaction authorization
    function fisherBridgeSend(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (tokenAddress == evvm.getEvvmMetadata().principalTokenAddress)
            revert Error.PrincipalTokenIsNotWithdrawable();

        if (evvm.getBalance(from, tokenAddress) < amount)
            revert Error.InsufficientBalance();

        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                evvm.getEvvmID(),
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) revert Error.InvalidSignature();

        nextFisherExecutionNonce[from]++;

        executerEVVM(false, from, tokenAddress, amount + priorityFee);

        if (priorityFee > 0)
            executerEVVM(true, msg.sender, tokenAddress, priorityFee);

        emit FisherBridgeSend(
            from,
            addressToReceive,
            tokenAddress,
            priorityFee,
            amount,
            nextFisherExecutionNonce[from] - 1
        );
    }

    // Hyperlane Specific Functions //

    /// @notice Calculates the fee required for Hyperlane cross-chain message dispatch
    /// @dev Queries the Hyperlane mailbox for accurate fee estimation
    /// @param toAddress Recipient address on the destination chain
    /// @param token Token contract address being transferred
    /// @param amount Amount of tokens being transferred
    /// @return Fee amount in native currency required for the Hyperlane message
    function getQuoteHyperlane(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        return
            IMailbox(hyperlane.mailboxAddress).quoteDispatch(
                hyperlane.externalChainStationDomainId,
                hyperlane.externalChainStationAddress,
                PayloadUtils.encodePayload(token, toAddress, amount)
            );
    }

    /// @notice Handles incoming Hyperlane messages from the external chain
    /// @dev Validates origin, sender authorization, and processes deposit to EVVM
    /// @param _origin Source chain domain ID where the message originated
    /// @param _sender Address of the message sender (must be external chain station)
    /// @param _data Encoded payload containing deposit instructions
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != hyperlane.mailboxAddress)
            revert Error.MailboxNotAuthorized();

        if (_sender != hyperlane.externalChainStationAddress)
            revert Error.SenderNotAuthorized();

        if (_origin != hyperlane.externalChainStationDomainId)
            revert Error.ChainIdNotAuthorized();

        decodeAndDeposit(_data);
    }

    // LayerZero Specific Functions //

    /// @notice Calculates the fee required for LayerZero cross-chain message
    /// @dev Queries LayerZero endpoint for accurate native fee estimation
    /// @param toAddress Recipient address on the destination chain
    /// @param token Token contract address being transferred
    /// @param amount Amount of tokens being transferred
    /// @return Native fee amount required for the LayerZero message
    function quoteLayerZero(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        MessagingFee memory fee = _quote(
            layerZero.externalChainStationEid,
            PayloadUtils.encodePayload(token, toAddress, amount),
            options,
            false
        );
        return fee.nativeFee;
    }

    /// @notice Handles incoming LayerZero messages from the external chain
    /// @dev Validates origin chain and sender, then processes deposit to EVVM
    /// @param _origin Origin information containing source endpoint ID and sender
    /// @param message Encoded payload containing deposit instructions
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/, // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/ // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the payload to get the message
        if (_origin.srcEid != layerZero.externalChainStationEid)
            revert Error.ChainIdNotAuthorized();

        if (_origin.sender != layerZero.externalChainStationAddress)
            revert Error.SenderNotAuthorized();

        decodeAndDeposit(message);
    }

    /// @notice Sends LayerZero messages to the destination chain
    /// @dev Handles fee payment and message dispatch through LayerZero endpoint
    /// @param _dstEid Destination endpoint ID (target chain)
    /// @param _message Encoded message payload to send
    /// @param _options Execution options for the destination chain
    /// @param _fee Messaging fee structure (native + LZ token fees)
    /// @param _refundAddress Address to receive excess fees
    /// @return receipt Messaging receipt with transaction details
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal override returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _fee.nativeFee;
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        return
            // solhint-disable-next-line check-send-result
            endpoint.send{value: messageValue}(
                MessagingParams(
                    _dstEid,
                    _getPeerOrRevert(_dstEid),
                    _message,
                    _options,
                    _fee.lzTokenFee > 0
                ),
                _refundAddress
            );
    }

    // Axelar Specific Functions //

    /// @notice Handles incoming Axelar messages from the external chain
    /// @dev Validates source chain and address, then processes deposit to EVVM
    /// @param _sourceChain Source blockchain name (must match configured external chain)
    /// @param _sourceAddress Source contract address (must match external chain station)
    /// @param _payload Encoded payload containing deposit instructions
    function _execute(
        bytes32 /*commandId*/,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        if (
            !AdvancedStrings.equal(
                _sourceChain,
                axelar.externalChainStationChainName
            )
        ) revert Error.ChainIdNotAuthorized();

        if (
            !AdvancedStrings.equal(
                _sourceAddress,
                axelar.externalChainStationAddress
            )
        ) revert Error.SenderNotAuthorized();

        decodeAndDeposit(_payload);
    }

    /// @notice Proposes a new admin address with 1-day time delay
    /// @dev Part of the time-delayed governance system for admin changes
    /// @param _newOwner Address of the proposed new admin (cannot be zero or current admin)
    function proposeAdmin(address _newOwner) external onlyAdmin {
        if (_newOwner == address(0) || _newOwner == admin.current) revert();

        admin.proposal = _newOwner;
        admin.timeToAccept = block.timestamp + 1 minutes;
    }

    /// @notice Cancels a pending admin change proposal
    /// @dev Allows current admin to reject proposed admin changes and reset proposal state
    function rejectProposalAdmin() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /// @notice Accepts a pending admin proposal and becomes the new admin
    /// @dev Can only be called by the proposed admin after the 1-day time delay
    function acceptAdmin() external {
        if (block.timestamp < admin.timeToAccept) revert();

        if (msg.sender != admin.proposal) revert();

        admin.current = admin.proposal;

        admin.proposal = address(0);
        admin.timeToAccept = 0;

        _transferOwnership(admin.current);
    }

    /// @notice Proposes a new Fisher executor address with 1-day time delay
    /// @dev Fisher executor handles cross-chain bridge transaction processing
    /// @param _newFisherExecutor Address of the proposed new Fisher executor
    function proposeFisherExecutor(
        address _newFisherExecutor
    ) external onlyAdmin {
        if (
            _newFisherExecutor == address(0) ||
            _newFisherExecutor == fisherExecutor.current
        ) revert();

        fisherExecutor.proposal = _newFisherExecutor;
        fisherExecutor.timeToAccept = block.timestamp + 1 minutes;
    }

    /// @notice Cancels a pending Fisher executor change proposal
    /// @dev Allows current admin to reject Fisher executor changes and reset proposal state
    function rejectProposalFisherExecutor() external onlyAdmin {
        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    /// @notice Accepts a pending Fisher executor proposal
    /// @dev Can only be called by the proposed Fisher executor after the 1-day time delay
    function acceptFisherExecutor() external {
        if (block.timestamp < fisherExecutor.timeToAccept) revert();

        if (msg.sender != fisherExecutor.proposal) revert();

        fisherExecutor.current = fisherExecutor.proposal;

        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    /// @notice Proposes new external chain addresses for all protocols with 1-day time delay
    /// @dev Updates addresses across Hyperlane, LayerZero, and Axelar simultaneously
    /// @param externalChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param externalChainStationAddressString String representation for Axelar protocol
    function proposeExternalChainAddress(
        address externalChainStationAddress,
        string memory externalChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetExternalChainAddress == 0x01) revert();

        externalChainAddressChangeProposal = ChangeExternalChainAddressParams({
            porposeAddress_AddressType: externalChainStationAddress,
            porposeAddress_StringType: externalChainStationAddressString,
            timeToAccept: block.timestamp + 1 minutes
        });
    }

    /// @notice Cancels a pending external chain address change proposal
    /// @dev Resets the external chain address proposal to default state
    function rejectProposalExternalChainAddress() external onlyAdmin {
        externalChainAddressChangeProposal = ChangeExternalChainAddressParams({
            porposeAddress_AddressType: address(0),
            porposeAddress_StringType: "",
            timeToAccept: 0
        });
    }

    /// @notice Accepts pending external chain address changes across all protocols
    /// @dev Updates Hyperlane, LayerZero, and Axelar configurations simultaneously
    function acceptExternalChainAddress() external {
        if (block.timestamp < externalChainAddressChangeProposal.timeToAccept)
            revert();

        hyperlane.externalChainStationAddress = bytes32(
            uint256(
                uint160(
                    externalChainAddressChangeProposal
                        .porposeAddress_AddressType
                )
            )
        );
        layerZero.externalChainStationAddress = bytes32(
            uint256(
                uint160(
                    externalChainAddressChangeProposal
                        .porposeAddress_AddressType
                )
            )
        );
        axelar.externalChainStationAddress = externalChainAddressChangeProposal
            .porposeAddress_StringType;
        _setPeer(
            layerZero.externalChainStationEid,
            layerZero.externalChainStationAddress
        );
    }

    // Getter functions //

    /// @notice Returns the complete admin configuration including proposals and timelock
    /// @return Current admin address, proposed admin, and acceptance timestamp
    function getAdmin() external view returns (AddressTypeProposal memory) {
        return admin;
    }

    /// @notice Returns the complete Fisher executor configuration including proposals
    /// @return Current Fisher executor, proposed executor, and acceptance timestamp
    function getFisherExecutor()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return fisherExecutor;
    }

    /// @notice Returns the next nonce for Fisher bridge operations for a specific user
    /// @dev Used to prevent replay attacks in cross-chain bridge transactions
    /// @param user Address to query the next Fisher execution nonce for
    /// @return Next sequential nonce value for the user's Fisher bridge operations
    function getNextFisherExecutionNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherExecutionNonce[user];
    }

    /// @notice Returns the EVVM core contract address
    /// @return Address of the EVVM contract used for balance operations
    function getEvvmAddress() external view returns (address) {
        return address(evvm);
    }

    /// @notice Returns the complete Hyperlane protocol configuration
    /// @return Hyperlane configuration including domain ID, external chain address, and mailbox
    function getHyperlaneConfig()
        external
        view
        returns (HyperlaneConfig memory)
    {
        return hyperlane;
    }

    /// @notice Returns the complete LayerZero protocol configuration
    /// @return LayerZero configuration including endpoint ID, external chain address, and endpoint
    function getLayerZeroConfig()
        external
        view
        returns (LayerZeroConfig memory)
    {
        return layerZero;
    }

    /// @notice Returns the complete Axelar protocol configuration
    /// @return Axelar configuration including chain name, addresses, gas service, and gateway
    function getAxelarConfig() external view returns (AxelarConfig memory) {
        return axelar;
    }

    /// @notice Returns the LayerZero execution options configuration
    /// @return Encoded options bytes for LayerZero message execution (200k gas limit)
    function getOptions() external view returns (bytes memory) {
        return options;
    }

    // Internal Functions //

    /// @notice Decodes cross-chain payload and credits EVVM balance
    /// @dev Extracts token, recipient, and amount from payload and adds to EVVM balance
    /// @param payload Encoded transfer data containing token, recipient, and amount
    function decodeAndDeposit(bytes memory payload) internal {
        (address token, address from, uint256 amount) = PayloadUtils
            .decodePayload(payload);
        executerEVVM(true, from, token, amount);
    }

    /// @notice Executes EVVM balance operations (add or remove)
    /// @dev Interface to EVVM's addAmountToUser and removeAmountFromUser functions
    /// @param typeOfExecution True to add balance, false to remove balance
    /// @param userToExecute Address whose balance will be modified
    /// @param token Token contract address for the balance operation
    /// @param amount Amount to add or remove from the user's balance
    function executerEVVM(
        bool typeOfExecution,
        address userToExecute,
        address token,
        uint256 amount
    ) internal {
        if (typeOfExecution) {
            // true = add
            evvm.addAmountToUser(userToExecute, token, amount);
        } else {
            // false = remove
            evvm.removeAmountFromUser(userToExecute, token, amount);
        }
    }

    /// @notice Disabled ownership transfer function for security
    /// @dev Ownership changes must go through the time-delayed admin proposal system
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {}

    /// @notice Disabled ownership renouncement function for security
    /// @dev Prevents accidental loss of administrative control over the contract
    function renounceOwnership() public virtual override onlyOwner {}
}
