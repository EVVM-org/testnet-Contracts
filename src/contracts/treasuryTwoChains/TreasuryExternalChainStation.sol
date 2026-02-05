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
                                                             
    ______     __                        __        __          _     
   / _____  __/ /____  _________  ____ _/ /  _____/ /_  ____ _(_____ 
  / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / ___/ __ \/ __ `/ / __ \
 / /____>  </ /_/  __/ /  / / / / /_/ / /  / /__/ / / / /_/ / / / / /
/_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/   \___/_/ /_/\__,_/_/_/ /_/ 
                                                                      
 * @title Treasury Cross-Chain Host Station Contract
 * @author Mate labs
 */

import {IERC20} from "@evvm/testnet-contracts/library/primitives/IERC20.sol";
import {
    CrossChainTreasuryError as Error
} from "@evvm/testnet-contracts/library/errors/CrossChainTreasuryError.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/ExternalChainStationStructs.sol";

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

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

contract TreasuryExternalChainStation is
    ExternalChainStationStructs,
    OApp,
    OAppOptionsType3,
    AxelarExecutable
{
    /// @notice Admin address management with time-delayed proposals
    /// @dev Stores current admin, proposed admin, and acceptance timestamp
    AddressTypeProposal admin;

    /// @notice Fisher executor address management with time-delayed proposals
    /// @dev Fisher executor can process cross-chain bridge transactions
    AddressTypeProposal fisherExecutor;

    /// @notice Hyperlane protocol configuration for cross-chain messaging
    /// @dev Contains domain ID, host chain address, and mailbox contract address
    HyperlaneConfig hyperlane;

    /// @notice LayerZero protocol configuration for omnichain messaging
    /// @dev Contains endpoint ID, host chain address, and endpoint contract address
    LayerZeroConfig layerZero;

    /// @notice Axelar protocol configuration for cross-chain communication
    /// @dev Contains chain name, host chain address, gas service, and gateway addresses
    AxelarConfig axelar;

    /// @notice Pending proposal for changing host chain addresses across all protocols
    /// @dev Used for coordinated updates to host chain addresses with time delay
    ChangeHostChainAddressParams hostChainAddressChangeProposal;

    /// @notice Unique identifier for the EVVM instance this station belongs to
    /// @dev Immutable value set at deployment for signature verification
    uint256 evvmID;

    uint256 windowTimeToChangeEvvmID;

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

    /// @notice One-time fuse for setting initial host chain addresses
    /// @dev Prevents multiple calls to _setHostChainAddress after initial setup
    bytes1 fuseSetHostChainAddress = 0x01;

    /// @notice Emitted when Fisher bridge sends tokens from external to host chain
    /// @param from Original sender address on external chain
    /// @param addressToReceive Recipient address on host chain
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

    /// @notice Initializes the External Chain Station with cross-chain protocol configurations
    /// @dev Sets up Hyperlane, LayerZero, and Axelar configurations for multi-protocol support
    /// @param _admin Initial admin address with full administrative privileges
    /// @param _crosschainConfig Configuration struct containing all cross-chain protocol settings
    constructor(
        address _admin,
        CrosschainConfig memory _crosschainConfig
    )
        OApp(_crosschainConfig.layerZero.endpointAddress, _admin)
        Ownable(_admin)
        AxelarExecutable(_crosschainConfig.axelar.gatewayAddress)
    {
        admin = AddressTypeProposal({
            current: _admin,
            proposal: address(0),
            timeToAccept: 0
        });
        hyperlane = HyperlaneConfig({
            hostChainStationDomainId: _crosschainConfig
                .hyperlane
                .hostChainStationDomainId,
            hostChainStationAddress: "",
            mailboxAddress: _crosschainConfig.hyperlane.mailboxAddress
        });
        layerZero = LayerZeroConfig({
            hostChainStationEid: _crosschainConfig
                .layerZero
                .hostChainStationEid,
            hostChainStationAddress: "",
            endpointAddress: _crosschainConfig.layerZero.endpointAddress
        });
        axelar = AxelarConfig({
            hostChainStationChainName: _crosschainConfig
                .axelar
                .hostChainStationChainName,
            hostChainStationAddress: "",
            gasServiceAddress: _crosschainConfig.axelar.gasServiceAddress,
            gatewayAddress: _crosschainConfig.axelar.gatewayAddress
        });
    }

    /// @notice One-time setup of host chain station address across all protocols
    /// @dev Can only be called once (protected by fuseSetHostChainAddress)
    /// @param hostChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param hostChainStationAddressString String representation for Axelar protocol
    function _setHostChainAddress(
        address hostChainStationAddress,
        string memory hostChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetHostChainAddress != 0x01) revert();

        hyperlane.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        layerZero.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        axelar.hostChainStationAddress = hostChainStationAddressString;
        _setPeer(
            layerZero.hostChainStationEid,
            layerZero.hostChainStationAddress
        );

        fuseSetHostChainAddress = 0x00;
    }

    /**
     * @notice Updates the EVVM ID with a new value, restricted to admin and time-limited
     * @dev Allows the admin to change the EVVM ID within a 1-day window after deployment
     */
    function setEvvmID(uint256 newEvvmID) external onlyAdmin {
        if (evvmID != 0) {
            if (block.timestamp > windowTimeToChangeEvvmID)
                revert Error.WindowToChangeEvvmIDExpired();
        }

        evvmID = newEvvmID;

        windowTimeToChangeEvvmID = block.timestamp + 24 hours;
    }

    /// @notice Deposits ERC20 tokens and sends them to host chain via selected protocol
    /// @dev Supports Hyperlane (0x01), LayerZero (0x02), and Axelar (0x03) protocols
    /// @param toAddress Recipient address on the host chain
    /// @param token ERC20 token contract address to deposit and transfer
    /// @param amount Amount of tokens to deposit and send to host chain
    /// @param protocolToExecute Protocol selector: 0x01=Hyperlane, 0x02=LayerZero, 0x03=Axelar
    function depositERC20(
        address toAddress,
        address token,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        bytes memory payload = PayloadUtils.encodePayload(
            token,
            toAddress,
            amount
        );
        verifyAndDepositERC20(token, amount);
        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, token, amount);
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 quote = quoteLayerZero(toAddress, token, amount);
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                options,
                MessagingFee(quote, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    /// @notice Deposits native ETH and sends it to host chain via selected protocol
    /// @dev msg.value must cover both the amount and protocol fees
    /// @param toAddress Recipient address on the host chain
    /// @param amount Amount of ETH to send to host chain (must be <= msg.value - fees)
    /// @param protocolToExecute Protocol selector: 0x01=Hyperlane, 0x02=LayerZero, 0x03=Axelar
    function depositCoin(
        address toAddress,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        if (msg.value < amount) revert Error.InsufficientBalance();

        bytes memory payload = PayloadUtils.encodePayload(
            address(0),
            toAddress,
            amount
        );

        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, address(0), amount);
            if (msg.value < quote + amount) revert Error.InsufficientBalance();
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 fee = quoteLayerZero(toAddress, address(0), amount);
            if (msg.value < fee + amount) revert Error.InsufficientBalance();
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                options,
                MessagingFee(fee, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value - amount}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    /// @notice Receives and validates Fisher bridge transactions from host chain
    /// @dev Verifies signature and increments nonce but doesn't transfer tokens (receive-only)
    /// @param from Original sender address from host chain
    /// @param addressToReceive Intended recipient address on this chain
    /// @param tokenAddress Token contract address (address(0) for ETH)
    /// @param priorityFee Fee amount for priority processing
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
                evvmID,
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
    }

    /// @notice Processes Fisher bridge ERC20 token transfers to host chain
    /// @dev Validates signature, deposits tokens, and emits tracking event
    /// @param from Original sender address initiating the bridge transaction
    /// @param addressToReceive Recipient address on the host chain
    /// @param tokenAddress ERC20 token contract address to bridge
    /// @param priorityFee Fee amount for priority processing
    /// @param amount Amount of tokens to bridge to host chain
    /// @param signature ECDSA signature proving transaction authorization
    function fisherBridgeSendERC20(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                evvmID,
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) revert Error.InvalidSignature();

        verifyAndDepositERC20(tokenAddress, amount);

        nextFisherExecutionNonce[from]++;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            tokenAddress,
            priorityFee,
            amount,
            nextFisherExecutionNonce[from] - 1
        );
    }

    /// @notice Processes Fisher bridge ETH transfers to host chain
    /// @dev Validates signature and exact payment (amount + priority fee)
    /// @param from Original sender address initiating the bridge transaction
    /// @param addressToReceive Recipient address on the host chain
    /// @param priorityFee Fee amount for priority processing
    /// @param amount Amount of ETH to bridge to host chain
    /// @param signature ECDSA signature proving transaction authorization
    function fisherBridgeSendCoin(
        address from,
        address addressToReceive,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external payable onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                evvmID,
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                address(0),
                priorityFee,
                amount,
                signature
            )
        ) revert Error.InvalidSignature();

        if (msg.value != amount + priorityFee)
            revert Error.InsufficientBalance();

        nextFisherExecutionNonce[from]++;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            address(0),
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
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                PayloadUtils.encodePayload(token, toAddress, amount)
            );
    }

    /// @notice Handles incoming Hyperlane messages from the host chain
    /// @dev Validates origin, sender authorization, and processes the payload
    /// @param _origin Source chain domain ID where the message originated
    /// @param _sender Address of the message sender (must be host chain station)
    /// @param _data Encoded payload containing transfer instructions
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != hyperlane.mailboxAddress)
            revert Error.MailboxNotAuthorized();

        if (_sender != hyperlane.hostChainStationAddress)
            revert Error.SenderNotAuthorized();

        if (_origin != hyperlane.hostChainStationDomainId)
            revert Error.ChainIdNotAuthorized();

        decodeAndGive(_data);
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
            layerZero.hostChainStationEid,
            PayloadUtils.encodePayload(token, toAddress, amount),
            options,
            false
        );
        return fee.nativeFee;
    }

    /// @notice Handles incoming LayerZero messages from the host chain
    /// @dev Validates origin chain and sender, then processes the transfer payload
    /// @param _origin Origin information containing source endpoint ID and sender
    /// @param message Encoded payload containing transfer instructions
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/, // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/ // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the payload to get the message
        if (_origin.srcEid != layerZero.hostChainStationEid)
            revert Error.ChainIdNotAuthorized();

        if (_origin.sender != layerZero.hostChainStationAddress)
            revert Error.SenderNotAuthorized();

        decodeAndGive(message);
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

    /// @notice Handles incoming Axelar messages from the host chain
    /// @dev Validates source chain and address, then processes the transfer payload
    /// @param _sourceChain Source blockchain name (must match configured host chain)
    /// @param _sourceAddress Source contract address (must match host chain station)
    /// @param _payload Encoded payload containing transfer instructions
    function _execute(
        bytes32 /*commandId*/,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        if (
            !AdvancedStrings.equal(
                _sourceChain,
                axelar.hostChainStationChainName
            )
        ) revert Error.ChainIdNotAuthorized();

        if (
            !AdvancedStrings.equal(
                _sourceAddress,
                axelar.hostChainStationAddress
            )
        ) revert Error.SenderNotAuthorized();

        decodeAndGive(_payload);
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

    /// @notice Proposes new host chain addresses for all protocols with 1-day time delay
    /// @dev Updates addresses across Hyperlane, LayerZero, and Axelar simultaneously
    /// @param hostChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param hostChainStationAddressString String representation for Axelar protocol
    function proposeHostChainAddress(
        address hostChainStationAddress,
        string memory hostChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetHostChainAddress == 0x01) revert();

        hostChainAddressChangeProposal = ChangeHostChainAddressParams({
            porposeAddress_AddressType: hostChainStationAddress,
            porposeAddress_StringType: hostChainStationAddressString,
            timeToAccept: block.timestamp + 1 minutes
        });
    }

    /// @notice Cancels a pending host chain address change proposal
    /// @dev Resets the host chain address proposal to default state
    function rejectProposalHostChainAddress() external onlyAdmin {
        hostChainAddressChangeProposal = ChangeHostChainAddressParams({
            porposeAddress_AddressType: address(0),
            porposeAddress_StringType: "",
            timeToAccept: 0
        });
    }

    /// @notice Accepts pending host chain address changes across all protocols
    /// @dev Updates Hyperlane, LayerZero, and Axelar configurations simultaneously
    function acceptHostChainAddress() external {
        if (block.timestamp < hostChainAddressChangeProposal.timeToAccept)
            revert();

        hyperlane.hostChainStationAddress = bytes32(
            uint256(
                uint160(
                    hostChainAddressChangeProposal.porposeAddress_AddressType
                )
            )
        );
        layerZero.hostChainStationAddress = bytes32(
            uint256(
                uint160(
                    hostChainAddressChangeProposal.porposeAddress_AddressType
                )
            )
        );
        axelar.hostChainStationAddress = hostChainAddressChangeProposal
            .porposeAddress_StringType;

        _setPeer(
            layerZero.hostChainStationEid,
            layerZero.hostChainStationAddress
        );
    }

    // Getter functions //

    /// @notice Returns the complete admin configuration including proposals and timelock
    /// @return Current admin address, proposed admin, and acceptance timestamp
    function getAdmin() external view returns (AddressTypeProposal memory) {
        return admin;
    }

    /// @notice Returns the complete Fisher executor configuration including proposals and timelock
    /// @return Current Fisher executor address, proposed executor, and acceptance timestamp
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

    /// @notice Returns the complete Hyperlane protocol configuration
    /// @return Hyperlane configuration including domain ID, host chain address, and mailbox
    function getHyperlaneConfig()
        external
        view
        returns (HyperlaneConfig memory)
    {
        return hyperlane;
    }

    /// @notice Returns the complete LayerZero protocol configuration
    /// @return LayerZero configuration including endpoint ID, host chain address, and endpoint
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

    /// @notice Decodes cross-chain payload and executes the token transfer
    /// @dev Handles both ETH (address(0)) and ERC20 token transfers to recipients
    /// @param payload Encoded transfer data containing token, recipient, and amount
    function decodeAndGive(bytes memory payload) internal {
        (address token, address toAddress, uint256 amount) = PayloadUtils
            .decodePayload(payload);
        if (token == address(0))
            SafeTransferLib.safeTransferETH(toAddress, amount);
        else IERC20(token).transfer(toAddress, amount);
    }

    /// @notice Validates and deposits ERC20 tokens from the caller
    /// @dev Verifies token approval and executes transferFrom to this contract
    /// @param token ERC20 token contract address (cannot be address(0))
    /// @param amount Amount of tokens to deposit and hold in this contract
    function verifyAndDepositERC20(address token, uint256 amount) internal {
        if (token == address(0)) revert();
        if (IERC20(token).allowance(msg.sender, address(this)) < amount)
            revert Error.InsufficientBalance();

        IERC20(token).transferFrom(msg.sender, address(this), amount);
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
