import { ChainData as ChainDataConstant, colors } from "../constants";
import type { ChainData } from "../types";
import { isChainIdRegistered } from "./foundry";
import {
  chainIdNotSupported,
  criticalError,
  criticalErrorCustom,
  warningCrossChainSuportNotAvailable,
} from "./outputMesages";
import {
  promptAddress,
  promptNumber,
  promptString,
  promptYesNo,
} from "./prompts";

export async function checkCrossChainSupport(
  chainId: number
): Promise<ChainData> {
  if (chainId === 31337 || chainId === 1337) {
    criticalErrorCustom(
      `Local blockchain detected (Chain ID: ${chainId}).`,
      `Please use a testnet host chain for cross-chain deployments.`
    );
  }
  if (!(await isChainIdRegistered(chainId))) chainIdNotSupported(chainId);

  if (!ChainDataConstant[chainId])
    criticalError(`Chain ID ${chainId} data not found in ChainData.json`);

  const chainData: ChainData = ChainDataConstant[chainId]!;

  let auxChainData = chainData;

  if (chainData.Hyperlane.MailboxAddress == "") {
    warningCrossChainSuportNotAvailable(
      chainData.Chain,
      chainId,
      "Hyperlane",
      "https://docs.hyperlane.xyz/docs/reference/addresses/deployments/mailbox#testnet"
    );

    if (
      await promptYesNo(
        `${colors.yellow}Do you want to add Hyperlane data? (y/n):${colors.reset}`
      )
    ) {
      auxChainData.Hyperlane.DomainId = await promptNumber(
        `${colors.yellow}Enter Hyperlane Domain ID for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
      auxChainData.Hyperlane.MailboxAddress = await promptAddress(
        `${colors.yellow}Enter Hyperlane Mailbox Address for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
    } else {
      if (
        !(await promptYesNo(
          `${colors.yellow}Do you want to continue without adding Hyperlane data? (y/n):${colors.reset}`
        ))
      ) {
        criticalErrorCustom(
          `User opted to not add Hyperlane data.`,
          `Cross-chain deployment cannot proceed without it.`
        );
      } else {
        auxChainData.Hyperlane.DomainId = 0;
        auxChainData.Hyperlane.MailboxAddress = "0x0000000000000000000000000000000000000000";
      }
    }
  }
  if (chainData!.LayerZero.EndpointAddress == "") {
    warningCrossChainSuportNotAvailable(
      chainData!.Chain,
      chainId,
      "LayerZero",
      "https://docs.layerzero.network/v2/deployments/deployed-contracts?stages=testnet"
    );

    if (
      await promptYesNo(
        `${colors.yellow}Do you want to add LayerZero data? (y/n):${colors.reset}`
      )
    ) {
      auxChainData.LayerZero.EId = await promptNumber(
        `${colors.yellow}Enter LayerZero EId for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
      auxChainData.LayerZero.EndpointAddress = await promptAddress(
        `${colors.yellow}Enter LayerZero Endpoint Address for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
    } else {
      if (
        !(await promptYesNo(
          `${colors.yellow}Do you want to continue without adding LayerZero data? (y/n):${colors.reset}`
        ))
      ) {
        criticalErrorCustom(
          `User opted to not add LayerZero data.`,
          `Cross-chain deployment cannot proceed without it.`
        );
      } else {
        auxChainData.LayerZero.EId = 0;
        auxChainData.LayerZero.EndpointAddress = "0x0000000000000000000000000000000000000000";
      }
    }
  }
  if (chainData!.Axelar.Gateway == "") {
    warningCrossChainSuportNotAvailable(
      chainData!.Chain,
      chainId,
      "Axelar",
      "https://axelarscan.io/resources/chains?type=evm"
    );

    if (
      await promptYesNo(
        `${colors.yellow}Do you want to add Axelar data? (y/n):${colors.reset}`
      )
    ) {
      auxChainData.Axelar.ChainName = await promptString(
        `${colors.yellow}Enter Axelar Chain Name for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
      auxChainData.Axelar.Gateway = await promptAddress(
        `${colors.yellow}Enter Axelar Gateway Address for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
      auxChainData.Axelar.GasService = await promptAddress(
        `${colors.yellow}Enter Axelar Gas Service Address for ${
          chainData!.Chain
        } (${chainId}):${colors.reset} `
      );
    } else {
      if (
        !(await promptYesNo(
          `${colors.yellow}Do you want to continue without adding Axelar data? (y/n):${colors.reset}`
        ))
      ) {
        criticalErrorCustom(
          `User opted to not add Axelar data.`,
          `Cross-chain deployment cannot proceed without it.`
        );
      } else {
        auxChainData.Axelar.ChainName = "";
        auxChainData.Axelar.Gateway = "0x0000000000000000000000000000000000000000";
        auxChainData.Axelar.GasService = "0x0000000000000000000000000000000000000000";
      }
    }
  }

  if (
    chainData.Hyperlane.MailboxAddress == "" ||
    chainData.LayerZero.EndpointAddress == "" ||
    chainData.Axelar.Gateway == ""
  ) {
    console.log(
      `\n${colors.bright}Cross-Chain Configuration for ${colors.blue}${chainData.Chain}${colors.reset} ${colors.darkGray}(${chainId})${colors.reset}${colors.bright}:${colors.reset}\n`
    );
    console.log(
      `${colors.bright}Hyperlane:${colors.reset}
  ${colors.darkGray}→${colors.reset} Domain ID: ${colors.blue}${auxChainData.Hyperlane.DomainId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Mailbox: ${colors.blue}${auxChainData.Hyperlane.MailboxAddress}${colors.reset}`
    );
    console.log(
      `\n${colors.bright}LayerZero:${colors.reset}
  ${colors.darkGray}→${colors.reset} EId: ${colors.blue}${auxChainData.LayerZero.EId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Endpoint: ${colors.blue}${auxChainData.LayerZero.EndpointAddress}${colors.reset}`
    );
    console.log(
      `\n${colors.bright}Axelar:${colors.reset}
  ${colors.darkGray}→${colors.reset} Chain Name: ${colors.blue}${auxChainData.Axelar.ChainName}${colors.reset}
  ${colors.darkGray}→${colors.reset} Gateway: ${colors.blue}${auxChainData.Axelar.Gateway}${colors.reset}
  ${colors.darkGray}→${colors.reset} Gas Service: ${colors.blue}${auxChainData.Axelar.GasService}${colors.reset}`
    );
    console.log();

    if (
      !promptYesNo(
        `${colors.yellow}Proceed with this configuration? (y/n):${colors.reset}`
      )
    ) {
      criticalError(
        `User cancelled due to incomplete cross-chain configuration.`
      );
    }
  }

  return auxChainData;
}
