/**
 * Help Command Module
 *
 * Displays comprehensive CLI usage information including available commands,
 * options, and examples. Provides detailed documentation for all EVVM CLI features,
 * deployment workflows, and best practices.
 *
 * @module cli/commands/help
 */

import { colors } from "../constants";
import { version } from "../../package.json";
import { showEvvmLogo } from "../utils/outputMesages";

/**
 * Displays the CLI help message with all available commands and options
 *
 * Outputs a formatted help screen including:
 * - Command descriptions and usage patterns
 * - Available options and flags for each command
 * - Example command invocations with common workflows
 * - Links to documentation and support resources
 *
 * @returns {void}
 */
export function showHelp() {

  console.log(`
${colors.bright}USAGE:${colors.reset}
  ${colors.blue}evvm${colors.reset} ${colors.yellow}<command>${colors.reset} ${colors.darkGray}[options]${colors.reset}

${colors.bright}COMMANDS:${colors.reset}
  ${colors.green}deploy${colors.reset}                    Deploy a new EVVM instance
                          ${colors.darkGray}Single-chain or cross-chain deployment${colors.reset}
                          ${colors.darkGray}Interactive wizard or use existing inputs${colors.reset}

  ${colors.green}register${colors.reset}                   Register an EVVM instance with the registry
                          ${colors.darkGray}Obtain globally unique EVVM ID${colors.reset}
                          ${colors.darkGray}Supports single-chain and cross-chain registration${colors.reset}

  ${colors.green}setUpCrossChainTreasuries${colors.reset}   Configure cross-chain treasury stations
                          ${colors.darkGray}Connect host and external chain treasuries${colors.reset}
                          ${colors.darkGray}Enable bidirectional asset transfers${colors.reset}

  ${colors.green}developer${colors.reset}                  Developer utilities and testing tools
                          ${colors.darkGray}Generate contract interfaces${colors.reset}
                          ${colors.darkGray}Run test suites with configurable options${colors.reset}

  ${colors.green}help${colors.reset}                       Display this help message

  ${colors.green}version${colors.reset}                    Show CLI version information

${colors.bright}DEPLOY OPTIONS:${colors.reset}
  ${colors.yellow}--skipInputConfig${colors.reset}, ${colors.yellow}-s${colors.reset}
                          Skip interactive prompts and use existing ./input/BaseInputs.sol

  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet name for transactions (default: defaultKey)

  ${colors.yellow}--walletNameHost${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet name for host chain (cross-chain only)

  ${colors.yellow}--walletNameExternal${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet name for external chain (cross-chain only)

  ${colors.yellow}--crossChain${colors.reset}, ${colors.yellow}-c${colors.reset}
                          Deploy a cross-chain EVVM instance with treasury stations

  ${colors.darkGray}Tip: Import keys securely with ${colors.bright}cast wallet import <name> --interactive${colors.reset}
  ${colors.darkGray}      Never store private keys in .env files${colors.reset}

${colors.bright}REGISTER OPTIONS:${colors.reset}
  ${colors.yellow}--coreAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                          Address of deployed EVVM contract to register

  ${colors.yellow}--treasuryExternalStationAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                          External chain station address (cross-chain only)

  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet for registry transactions (default: defaultKey)

  ${colors.yellow}--walletNameHost${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet for host chain (cross-chain only)

  ${colors.yellow}--walletNameExternal${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet for external chain (cross-chain only)

  ${colors.yellow}--useCustomEthRpc${colors.reset}
                          Use custom Ethereum Sepolia RPC for registry operations
                          ${colors.darkGray}Reads EVVM_REGISTRATION_RPC_URL from .env or prompts${colors.reset}

  ${colors.yellow}--crossChain${colors.reset}, ${colors.yellow}-c${colors.reset}
                          Register a cross-chain EVVM instance

${colors.bright}SETUP CROSS-CHAIN OPTIONS:${colors.reset}
  ${colors.yellow}--treasuryHostStationAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                          Address of host chain treasury station contract

  ${colors.yellow}--treasuryExternalStationAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                          Address of external chain treasury station contract

  ${colors.yellow}--walletNameHost${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet for host chain operations

  ${colors.yellow}--walletNameExternal${colors.reset} ${colors.darkGray}<name>${colors.reset}
                          Foundry wallet for external chain operations

${colors.bright}DEVELOPER OPTIONS:${colors.reset}
  ${colors.yellow}--makeInterface${colors.reset}, ${colors.yellow}-i${colors.reset}
                          Generate Solidity interfaces from contract implementations

  ${colors.yellow}--runTest${colors.reset}, ${colors.yellow}-t${colors.reset}
                          Run test suites with configurable options

${colors.bright}GLOBAL OPTIONS:${colors.reset}
  ${colors.yellow}-h${colors.reset}, ${colors.yellow}--help${colors.reset}              Show this help message
  ${colors.yellow}-v${colors.reset}, ${colors.yellow}--version${colors.reset}           Show CLI version

${colors.bright}DEPLOYMENT WORKFLOWS:${colors.reset}

  ${colors.darkGray}Single-Chain Deployment:${colors.reset}
  ${colors.blue}1. Configure addresses and metadata:${colors.reset}
     ${colors.evvmGreen}evvm deploy${colors.reset}

  ${colors.blue}2. Or skip configuration and use existing inputs:${colors.reset}
     ${colors.evvmGreen}evvm deploy --skipInputConfig${colors.reset}

  ${colors.blue}3. Register your EVVM instance:${colors.reset}
     ${colors.evvmGreen}evvm register --coreAddress <address> --walletName <name>${colors.reset}

  ${colors.darkGray}Cross-Chain Deployment:${colors.reset}
  ${colors.blue}1. Deploy EVVM with treasury stations on both chains:${colors.reset}
     ${colors.evvmGreen}evvm deploy --crossChain${colors.reset}

  ${colors.blue}2. Set up communication between treasuries:${colors.reset}
     ${colors.evvmGreen}evvm setUpCrossChainTreasuries \\${colors.reset}
     ${colors.evvmGreen}  --treasuryHostStationAddress <address> \\${colors.reset}
     ${colors.evvmGreen}  --treasuryExternalStationAddress <address> \\${colors.reset}
     ${colors.evvmGreen}  --walletNameHost <name> --walletNameExternal <name>${colors.reset}

  ${colors.blue}3. Register your cross-chain EVVM:${colors.reset}
     ${colors.evvmGreen}evvm register --crossChain \\${colors.reset}
     ${colors.evvmGreen}  --coreAddress <address> \\${colors.reset}
     ${colors.evvmGreen}  --treasuryExternalStationAddress <address> \\${colors.reset}
     ${colors.evvmGreen}  --walletName <name>${colors.reset}

${colors.bright}WALLET SETUP:${colors.reset}

  ${colors.blue}Import a new wallet securely:${colors.reset}
  ${colors.evvmGreen}cast wallet import myWallet --interactive${colors.reset}

  ${colors.blue}List available wallets:${colors.reset}
  ${colors.evvmGreen}cast wallet list${colors.reset}

${colors.bright}TESTING:${colors.reset}

  ${colors.blue}Run all contract tests:${colors.reset}
  ${colors.evvmGreen}evvm developer --runTest${colors.reset}

  ${colors.blue}Generate contract interfaces:${colors.reset}
  ${colors.evvmGreen}evvm developer --makeInterface${colors.reset}

${colors.bright}DOCUMENTATION:${colors.reset}
  ${colors.blue}https://www.evvm.info/docs${colors.reset}
  ${colors.blue}https://www.evvm.info/docs/QuickStart${colors.reset}

${colors.bright}SUPPORT & ISSUES:${colors.reset}
  ${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}
  `);
}