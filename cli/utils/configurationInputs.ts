import { colors } from "../constants";
import {
  promptString,
  promptNumber,
  promptAddress,
  promptYesNo,
} from "./prompts";
import { formatNumber } from "./validators";
import type {
  BaseInputAddresses,
  CrossChainInputs,
  EvvmMetadata,
} from "../types";
import { getRPCUrlAndChainId } from "../utils/rpc";
import { checkCrossChainSupport } from "../utils/crossChain";
import { getAddress } from "viem/utils";
import {
  baseConfigurationSummary,
  confirmation,
  criticalError,
  crossChainConfigurationSummary,
} from "./outputMesages";
import { checkDirectoryPath, writeFilePath } from "./fileManagement";

/**
 * Interactive configuration wizard for EVVM deployment.
 * Collects addresses and metadata, validates inputs, and writes to file.
 *
 * @returns {Promise<boolean>} - Returns true if configuration is confirmed and saved, false otherwise.
 */
export async function configurationBasic() {
  let evvmMetadata: EvvmMetadata = {
    EvvmName: "EVVM",
    EvvmID: 0,
    principalTokenName: "Mate Token",
    principalTokenSymbol: "MATE",
    principalTokenAddress: "0x0000000000000000000000000000000000000001",
    totalSupply: 2033333333000000000000000000,
    eraTokens: 1016666666500000000000000000,
    reward: 5000000000000000000,
  };

  let addresses: BaseInputAddresses = {
    admin: null,
    goldenFisher: null,
    activator: null,
  };

  do {
    for (const key of Object.keys(addresses) as (keyof BaseInputAddresses)[]) {
      addresses[key] = await promptAddress(
        `${colors.yellow}Enter the ${key} address:${colors.reset}`
      );
    }

    evvmMetadata.EvvmName = await promptString(
      `${colors.yellow}EVVM Name ${colors.darkGray}[${evvmMetadata.EvvmName}]:${colors.reset}`,
      evvmMetadata.EvvmName ?? undefined
    );

    evvmMetadata.principalTokenName = await promptString(
      `${colors.yellow}Principal Token Name ${colors.darkGray}[${evvmMetadata.principalTokenName}]:${colors.reset}`,
      evvmMetadata.principalTokenName ?? undefined
    );

    evvmMetadata.principalTokenSymbol = await promptString(
      `${colors.yellow}Principal Token Symbol ${colors.darkGray}[${evvmMetadata.principalTokenSymbol}]:${colors.reset}`,
      evvmMetadata.principalTokenSymbol ?? undefined
    );

    if (
      await promptYesNo(
        `${colors.yellow}Configure advanced metadata (totalSupply, eraTokens, reward)? (y/n):${colors.reset}`
      )
    ) {
      evvmMetadata.totalSupply = await promptNumber(
        `${colors.yellow}Total Supply ${colors.darkGray}[${formatNumber(
          evvmMetadata.totalSupply
        )}]:${colors.reset}`,
        evvmMetadata.totalSupply ?? undefined
      );

      evvmMetadata.eraTokens = await promptNumber(
        `${colors.yellow}Era Tokens ${colors.darkGray}[${formatNumber(
          evvmMetadata.eraTokens
        )}]:${colors.reset}`,
        evvmMetadata.eraTokens ?? undefined
      );

      evvmMetadata.reward = await promptNumber(
        `${colors.yellow}Reward ${colors.darkGray}[${formatNumber(
          evvmMetadata.reward
        )}]:${colors.reset}`,
        evvmMetadata.reward ?? undefined
      );
    }

    baseConfigurationSummary(addresses, evvmMetadata);
  } while (
    !(await promptYesNo(`${colors.yellow}Confirm configuration? (y/n):${colors.reset}`))
  );

  await writeBaseInputsFile(addresses, evvmMetadata);

  confirmation(
    `${colors.reset}Input configuration saved to ${colors.darkGray}./input/BaseInputs.sol${colors.reset}`
  );
}

/**
 * Interactive cross-chain configuration wizard for EVVM deployment.
 * Collects external and host chain data, validates inputs, and writes to file.
 *
 * @returns {Promise<{externalRpcUrl: string | null; externalChainId: number | null; hostRpcUrl: string | null; hostChainId: number | null}>} - Returns external and host RPC URLs and chain IDs if configuration is confirmed and saved, nulls otherwise.
 */
export async function configurationCrossChain(): Promise<{
  externalRpcUrl: string;
  externalChainId: number;
  hostRpcUrl: string;
  hostChainId: number;
}> {
  let crossChainInputs: CrossChainInputs = {
    adminExternal: "0x0000000000000000000000000000000000000000",
    crosschainConfigHost: {
      hyperlane: {
        externalChainStationDomainId: 0,
        mailboxAddress: "0x0000000000000000000000000000000000000000",
      },
      layerZero: {
        externalChainStationEid: 0,
        endpointAddress: "0x0000000000000000000000000000000000000000",
      },
      axelar: {
        externalChainStationChainName: "",
        gatewayAddress: "0x0000000000000000000000000000000000000000",
        gasServiceAddress: "0x0000000000000000000000000000000000000000",
      },
    },
    crosschainConfigExternal: {
      hyperlane: {
        hostChainStationDomainId: 0,
        mailboxAddress: "0x0000000000000000000000000000000000000000",
      },
      layerZero: {
        hostChainStationEid: 0,
        endpointAddress: "0x0000000000000000000000000000000000000000",
      },
      axelar: {
        hostChainStationChainName: "",
        gatewayAddress: "0x0000000000000000000000000000000000000000",
        gasServiceAddress: "0x0000000000000000000000000000000000000000",
      },
    },
  };

  let externalRpcUrl: string = "";
  let externalChainId: number = 0;
  let hostRpcUrl: string = "";
  let hostChainId: number = 0;

  do {
    ({ rpcUrl: externalRpcUrl, chainId: externalChainId } =
      await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL)),
      `${colors.yellow}Please enter the External Chain RPC URL:${colors.reset}`;

    let externalChainData = await checkCrossChainSupport(externalChainId!);

    ({ rpcUrl: hostRpcUrl, chainId: hostChainId } = await getRPCUrlAndChainId(
      process.env.HOST_RPC_URL,
      `${colors.yellow}Please enter the Host Chain RPC URL:${colors.reset}`
    ));

    let hostChainData = await checkCrossChainSupport(hostChainId!);

    let addressAdminExternal = await promptAddress(
      `${colors.yellow}Enter the external admin address:${colors.reset}`
    );

    crossChainInputs = {
      adminExternal: addressAdminExternal,
      crosschainConfigHost: {
        hyperlane: {
          externalChainStationDomainId: externalChainData.Hyperlane.DomainId,
          mailboxAddress: externalChainData.Hyperlane
            .MailboxAddress as `0x${string}`,
        },
        layerZero: {
          externalChainStationEid: externalChainData.LayerZero.EId,
          endpointAddress: externalChainData.LayerZero
            .EndpointAddress as `0x${string}`,
        },
        axelar: {
          externalChainStationChainName: externalChainData.Axelar.ChainName,
          gatewayAddress: externalChainData.Axelar.Gateway as `0x${string}`,
          gasServiceAddress: externalChainData.Axelar
            .GasService as `0x${string}`,
        },
      },
      crosschainConfigExternal: {
        hyperlane: {
          hostChainStationDomainId: hostChainData.Hyperlane.DomainId,
          mailboxAddress: hostChainData.Hyperlane
            .MailboxAddress as `0x${string}`,
        },
        layerZero: {
          hostChainStationEid: hostChainData.LayerZero.EId,
          endpointAddress: hostChainData.LayerZero
            .EndpointAddress as `0x${string}`,
        },
        axelar: {
          hostChainStationChainName: hostChainData.Axelar.ChainName,
          gatewayAddress: hostChainData.Axelar.Gateway as `0x${string}`,
          gasServiceAddress: hostChainData.Axelar.GasService as `0x${string}`,
        },
      },
    };

    crossChainConfigurationSummary(
      externalChainData,
      hostChainData,
      crossChainInputs
    );
  } while (
    !(await promptYesNo(
      `${colors.yellow}Confirm cross-chain configuration? (y/n):${colors.reset}`
    ))
  );

  await writeCrossChainInputsFile(crossChainInputs);

  confirmation(
    `${colors.reset}Cross-chain input configuration saved to ${colors.darkGray}./input/CrossChainInputs.sol${colors.reset}`
  );

  return {
    externalRpcUrl: externalRpcUrl!,
    externalChainId: externalChainId!,
    hostRpcUrl: hostRpcUrl!,
    hostChainId: hostChainId!,
  };
}

/**
 * Generates and writes the BaseInputs.sol file with deployment configuration
 *
 * Creates a Solidity contract containing all deployment parameters including
 * admin addresses and EVVM metadata. This file is used by the deployment script.
 *
 * @param {BaseInputAddresses} addresses - Admin, golden fisher, and activator addresses
 * @param {EvvmMetadata} evvmMetadata - EVVM configuration including token economics
 * @returns {Promise<boolean>} True if file was written successfully
 */
export async function writeBaseInputsFile(
  addresses: BaseInputAddresses,
  evvmMetadata: EvvmMetadata
) {
  const inputDir = "./input";
  const inputFile = `${inputDir}/BaseInputs.sol`;

  if (
    addresses.admin == undefined ||
    addresses.goldenFisher == undefined ||
    addresses.activator == undefined
  )
    criticalError(`Invalid addresses provided to write BaseInputs file.`);

  await checkDirectoryPath(inputDir);

  const inputFileContent = `// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";

abstract contract BaseInputs {
    address admin = ${getAddress(addresses.admin!)};
    address goldenFisher = ${getAddress(addresses.goldenFisher!)};
    address activator = ${getAddress(addresses.activator!)};

    CoreStructs.EvvmMetadata inputMetadata =
        CoreStructs.EvvmMetadata({
            EvvmName: "${evvmMetadata.EvvmName}",
            // evvmID will be set to 0, and it will be assigned when you register the evvm
            EvvmID: 0,
            principalTokenName: "${evvmMetadata.principalTokenName}",
            principalTokenSymbol: "${evvmMetadata.principalTokenSymbol}",
            principalTokenAddress: ${evvmMetadata.principalTokenAddress},
            totalSupply: ${formatNumber(evvmMetadata.totalSupply)},
            eraTokens: ${formatNumber(evvmMetadata.eraTokens)},
            reward: ${formatNumber(evvmMetadata.reward)}
        });
}
`;

  await writeFilePath(inputFile, inputFileContent);
}

/**
 * Generates and writes the CrossChainInputs.sol file with cross-chain configuration
 *
 * Creates a Solidity contract containing all cross-chain messaging parameters for
 * both host and external chain stations. Used by cross-chain deployment scripts.
 *
 * @param {CrossChainInputs} crossChainInputs - Cross-chain configuration for Hyperlane, LayerZero, and Axelar
 * @returns {Promise<boolean>} True if file was written successfully
 */
export async function writeCrossChainInputsFile(
  crossChainInputs: CrossChainInputs
) {
  const inputDir = "./input";
  const inputFile = `${inputDir}/CrossChainInputs.sol`;

  await checkDirectoryPath(inputDir);

  const inputFileContent = `// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    HostChainStationStructs
} from "@evvm/testnet-contracts/library/structs/HostChainStationStructs.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/library/structs/ExternalChainStationStructs.sol";

abstract contract CrossChainInputs {
    address constant adminExternal = ${getAddress(
      crossChainInputs.adminExternal
    )};

    HostChainStationStructs.CrosschainConfig crosschainConfigHost =
        HostChainStationStructs.CrosschainConfig({
            hyperlane: HostChainStationStructs.HyperlaneConfig({
                externalChainStationDomainId: ${
                  crossChainInputs.crosschainConfigHost.hyperlane
                    .externalChainStationDomainId
                }, //Domain ID for External on Hyperlane
                externalChainStationAddress: bytes32(0), //External Chain Station Address on Hyperlane
                mailboxAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.hyperlane
                    .mailboxAddress
                )} //Mailbox for Host on Hyperlane
            }),
            layerZero: HostChainStationStructs.LayerZeroConfig({
                externalChainStationEid: ${
                  crossChainInputs.crosschainConfigHost.layerZero
                    .externalChainStationEid
                }, //EID for External on LayerZero
                externalChainStationAddress: bytes32(0), //External Chain Station Address on LayerZero
                endpointAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.layerZero
                    .endpointAddress
                )} //Endpoint for Host on LayerZero
            }),
            axelar: HostChainStationStructs.AxelarConfig({
                externalChainStationChainName: "${
                  crossChainInputs.crosschainConfigHost.axelar
                    .externalChainStationChainName
                }", //Chain Name for External on Axelar
                externalChainStationAddress: "", //External Chain Station Address on Axelar
                gasServiceAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.axelar
                    .gasServiceAddress
                )}, //Gas Service for External on Axelar
                gatewayAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.axelar
                    .gatewayAddress
                )} //Gateway for Host on Axelar
            })
        });

    ExternalChainStationStructs.CrosschainConfig crosschainConfigExternal =
        ExternalChainStationStructs.CrosschainConfig({
            hyperlane: ExternalChainStationStructs.HyperlaneConfig({
                hostChainStationDomainId: ${
                  crossChainInputs.crosschainConfigExternal.hyperlane
                    .hostChainStationDomainId
                }, //Domain ID for Host on Hyperlane
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on Hyperlane
                mailboxAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.hyperlane.mailboxAddress
                )} //Mailbox for External on Hyperlane
            }),
            layerZero: ExternalChainStationStructs.LayerZeroConfig({
                hostChainStationEid: ${
                  crossChainInputs.crosschainConfigExternal.layerZero
                    .hostChainStationEid
                }, //EID for Host on LayerZero
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on LayerZero
                endpointAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.layerZero
                    .endpointAddress
                )} //Endpoint for External on LayerZero
            }),
            axelar: ExternalChainStationStructs.AxelarConfig({
                hostChainStationChainName: "${
                  crossChainInputs.crosschainConfigExternal.axelar
                    .hostChainStationChainName
                }", //Chain Name for Host on Axelar
                hostChainStationAddress: "", //Host Chain Station Address on Axelar
                gasServiceAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.axelar.gasServiceAddress
                )}, //Gas Service for External on Axelar
                gatewayAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.axelar.gatewayAddress
                )} //Gateway for External on Axelar
            })
        });
}
`;

  await writeFilePath(inputFile, inputFileContent);
}
