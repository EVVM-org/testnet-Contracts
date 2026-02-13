# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.0.x   | :white_check_mark: |
| < 2.3   | :x:                |

## Reporting a Vulnerability

We take the security of EVVM contracts seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report vulnerabilities through one of these channels:

1. **GitHub Security Advisories** (Preferred)
   - Go to the [Security tab](../../security/advisories) of this repository
   - Click "Report a vulnerability"
   - Provide detailed information about the vulnerability

2. **Email**
   - Send an email to: `jistro@evvm.dev` (replace with your actual security email)
   - Use the subject line: `[SECURITY] EVVM Vulnerability Report`

### What to Include

Please include the following information in your report:

- **Description**: A clear description of the vulnerability
- **Affected Component(s)**:
  - [ ] EVVM Core (`evvm/`)
  - [ ] Name Service (`nameService/`)
  - [ ] Staking (`staking/`)
  - [ ] Treasury (`treasury/`)
  - [ ] State (`state/`)
  - [ ] Library (`library/`)
  - [ ] CLI Tools (`cli/`)
  - [ ] Other: _______________
- **Severity Assessment**: Your assessment of the severity (Critical/High/Medium/Low)
- **Steps to Reproduce**: Detailed steps to reproduce the vulnerability
- **Proof of Concept**: If possible, provide a PoC (code, transaction, or test case)
- **Impact**: Potential impact if the vulnerability is exploited
- **Suggested Fix**: If you have ideas on how to fix it (optional)

### Response Timeline

| Action | Timeline |
|--------|----------|
| Initial acknowledgment | Within 48 hours |
| Preliminary assessment | Within 1 week |
| Detailed response/fix timeline | Within 2 weeks |
| Security patch release | Depends on severity |

### Severity Levels

| Severity | Description | Examples |
|----------|-------------|----------|
| **Critical** | Direct loss of funds, complete system compromise | Unauthorized fund transfers, reentrancy attacks enabling theft |
| **High** | Significant impact on contract functionality or partial fund loss | Bypass of access controls, manipulation of critical state |
| **Medium** | Limited impact, workarounds available | Griefing attacks, denial of service |
| **Low** | Minimal impact, informational | Gas optimizations, code quality issues |

## Security Best Practices

### For Users

- Always verify contract addresses before interacting
- Use hardware wallets for significant transactions
- Double-check transaction parameters before signing
- Be cautious of phishing attempts

### For Developers

- Follow the [Solidity security best practices](https://docs.soliditylang.org/en/latest/security-considerations.html)
- Run all tests before submitting PRs: `forge test`
- Use static analysis tools (Slither, Mythril)
- Review changes for common vulnerabilities:
  - Reentrancy
  - Integer overflow/underflow
  - Access control issues
  - Front-running vulnerabilities
  - Signature replay attacks

## Smart Contract Audits

### Completed Audits

<!-- Update this section with actual audit information -->
| Auditor | Date | Scope | Report |
|---------|------|-------|--------|
| TBD | TBD | TBD | [Link]() |

### Bug Bounty Program

<!-- Update this section if you have a bug bounty program -->
We are considering implementing a bug bounty program. Details will be announced here when available.

## Disclosure Policy

- We follow a **responsible disclosure** policy
- Security researchers will be credited (unless they prefer anonymity)
- We aim to fix critical vulnerabilities within 7 days
- Public disclosure will occur after a fix is deployed and users have had time to update

## AI Assistance Disclosure

If you used AI tools while discovering or analyzing a vulnerability, please mention this in your report. This helps us understand the nature of the discovery and improve our security practices.

## Contact

For non-security related questions, please use:
- GitHub Issues for bugs and features
- GitHub Discussions for general questions

---

Thank you for helping keep EVVM secure!
