# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-02-03

### Added
- Initial Terraform infrastructure
  - VPC 10.0.0.0/16 with public subnet
  - Internet Gateway and routing
  - Security groups for vMix and Cuez
  - EC2 instances (t3.xlarge for vMix, t3.large for Cuez)
  - 500GB gp3 EBS volumes
- PowerShell setup scripts
  - setup-vmix.ps1 with Chocolatey, 7zip, git, curl
  - setup-cuez.ps1 with IIS installation
- Security allowlist for providers
  - ALGAR, MUNDIVOX, EMBRATEL, SAMM
- Documentation
  - README.md with quick start guide
  - CLAUDE.md for AI context
  - COMMANDS.md with useful commands
  - Architecture diagram

### Security
- Implemented IP allowlist for all public-facing ports
- Enabled EBS encryption
- Configured Windows Firewall rules in setup scripts

[Unreleased]: https://github.com/jniorpoa/cuez-cloud/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jniorpoa/cuez-cloud/releases/tag/v0.1.0
