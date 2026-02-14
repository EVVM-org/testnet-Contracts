#!/usr/bin/env bun

/**
 * EVVM CLI Entry Point
 *
 * Main command-line interface for EVVM contract deployment, registration,
 * and cross-chain configuration. Provides an interactive wizard-based workflow
 * with validation, error handling, and integration with Foundry tooling.
 *
 * Supported operations:
 * - Single-chain and cross-chain EVVM deployment
 * - EVVM Registry registration on Ethereum Sepolia
 * - Cross-chain treasury station connection
 * - Developer utilities (interface generation, testing)
 *
 * @module cli/index
 */

import { parseArgs } from "util";
import { colors } from "./constants";
import { register, showHelp, showVersion } from "./commands";
import { developer, installDependencies } from "./commands/developer";
import { setUpCrossChainTreasuries } from "./commands/setUpCrossChainTreasuries";
import { deploy } from "./commands/deploy";
import { showEvvmLogo } from "./utils/outputMesages";
import { promptSelect } from "./utils/prompts";

/**
 * Available CLI commands mapped to their handler functions
 *
 * @constant {Object} commands - Command name to handler function mapping
 * @property {Function} help - Display CLI help and usage information
 * @property {Function} version - Display CLI version number
 * @property {Function} deploy - Deploy EVVM contracts (single or cross-chain)
 * @property {Function} register - Register EVVM in registry (single or cross-chain)
 * @property {Function} setUpCrossChainTreasuries - Connect host and external treasury stations
 * @property {Function} dev - Developer utilities and tooling
 */
const commands = {
  help: showHelp,
  version: showVersion,
  deploy: deploy,
  register: register,
  setUpCrossChainTreasuries: setUpCrossChainTreasuries,
  dev: developer,
  install: installDependencies
};

/**
 * Main CLI execution function
 *
 * Orchestrates the CLI workflow:
 * 1. Parses command-line arguments using Node's util.parseArgs
 * 2. Handles global flags (--help, --version)
 * 3. Routes to appropriate command handler
 * 4. Provides error handling for unknown commands
 *
 * Supported global flags:
 * - --help, -h: Display comprehensive help information
 * - --version, -v: Display CLI version number
 * - --verbose: Enable verbose logging (reserved for future use)
 *
 * Command-specific options are passed through to individual handlers.
 *
 * @returns {Promise<void>}
 * @throws {Error} When an unknown command is provided (exits with code 1)
 */
async function main() {
  const args = process.argv.slice(2);

  showEvvmLogo();

  if (args.length === 0) {
    const selection = await promptSelect("Select an option to continue:", [
      "Deploy EVVM Contracts",
      "Register EVVM in Registry",
      "Set Up Cross-Chain Treasuries",
      "Developer Utilities",
      "Exit",
    ]);
    switch (selection) {
      case "Deploy EVVM Contracts":
        args.push("deploy");
        break;
      case "Register EVVM in Registry":
        args.push("register");
        break;
      case "Set Up Cross-Chain Treasuries":
        args.push("setUpCrossChainTreasuries");
        break;
      case "Developer Utilities":
        args.push("dev");
        break;
      case "Exit":
        console.log("Exiting...");
        process.exit(0);
      default:
        console.error(
          `${colors.red}Error: Unknown selection "${selection}"${colors.reset}`
        );
        process.exit(1);
    }

    if (selection === "Deploy EVVM Contracts") {
      const deployType = await promptSelect("Select deployment type:", [
        "Single-Chain Deployment",
        "Cross-Chain Deployment",
      ]);
      switch (deployType) {
        case "Single-Chain Deployment":
          break;
        case "Cross-Chain Deployment":
          args.push("--crossChain");
          break;
        default:
          console.error(
            `${colors.red}Error: Unknown selection "${deployType}"${colors.reset}`
          );
          process.exit(1);
      }
    }

    if (selection === "Register EVVM in Registry") {
      const registerType = await promptSelect("Select registration type:", [
        "Single-Chain Registration",
        "Cross-Chain Registration",
      ]);
      switch (registerType) {
        case "Single-Chain Registration":
          break;
        case "Cross-Chain Registration":
          args.push("--crossChain");
          break;
        default:
          console.error(
            `${colors.red}Error: Unknown selection "${registerType}"${colors.reset}`
          );
          process.exit(1);
      }
    }
  }

  /**
   * Parse command-line arguments with comprehensive option definitions
   *
   * Global options:
   * - help, version: Display help or version information
   * - verbose: Enable verbose output (reserved for future use)
   * - crossChain: Enable cross-chain deployment/registration mode
   *
   * Deployment options:
   * - skipInputConfig: Use configuration files instead of interactive prompts
   * - walletName/walletNameHost/walletNameExternal: Foundry wallet account names
   *
   * Registration options:
   * - coreAddress: Address of deployed EVVM contract
   * - useCustomEthRpc: Use custom Ethereum Sepolia RPC for registry calls
   *
   * Cross-chain setup options:
   * - treasuryHostStationAddress: Host chain treasury station address
   * - treasuryExternalStationAddress: External chain treasury station address
   *
   * Developer options:
   * - makeInterface: Generate Solidity interfaces from contracts
   */
  const { values, positionals } = parseArgs({
    args,
    options: {
      // general options
      help: { type: "boolean", short: "h" },
      version: { type: "boolean", short: "v" },
      verbose: { type: "boolean" },
      crossChain: { type: "boolean", short: "c" },

      // general deploy command options
      skipInputConfig: { type: "boolean", short: "s" },
      walletName: { type: "string", short: "n" },

      // setUpCrossChainTreasuries command specific
      treasuryHostStationAddress: { type: "string" },
      treasuryExternalStationAddress: { type: "string" },
      walletNameHost: { type: "string" },
      walletNameExternal: { type: "string" },

      // register command specific
      coreAddress: { type: "string" },
      useCustomEthRpc: { type: "boolean" },

      //dev command specific
      makeInterface: { type: "boolean", short: "i" },
      runTest: { type: "boolean", short: "t" },
    },
    allowPositionals: true,
  });

  // Global flags
  if (values.help) {
    showHelp();
    return;
  }

  if (values.version) {
    showVersion();
    return;
  }

  // Execute command
  const command = positionals[0];
  const handler = commands[command as keyof typeof commands];

  if (handler) {
    await handler(positionals.slice(1), values);
  } else {
    console.error(
      `${colors.red}Error: Unknown command "${command}"${colors.reset}`
    );
    console.log(
      `Use ${colors.bright}--help${colors.reset} to see available commands\n`
    );
    process.exit(1);
  }
}

// Global error handling
process.on("uncaughtException", (error) => {
  console.error(`${colors.red}Fatal error:${colors.reset}`, error.message);
  process.exit(1);
});

// Execute
main().catch((error) => {
  console.error(`${colors.red}Error:${colors.reset}`, error.message);
  process.exit(1);
});
