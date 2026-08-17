# IaC Platform Hub (Sample)

This repository is a **boilerplate IaC Platform Hub** for automating cloud infrastructure deployment in **Microsoft Azure** and supporting configuration management for a **Node.js application**. It provides a reusable, test-friendly foundation to standardize how infrastructure is defined, validated, and deployed across environments using Infrastructure as Code practices.

## High-Level Goals

- Standardize Azure resource provisioning through Infrastructure-as-Code that is reusable and modular.
- Enable repeatable deployments across environments (e.g., dev/staging/prod).
- Support Node.js app configuration through infrastructure-driven setup.
- Serve as a technical assessment reference implementation for platform engineering workflows.

## Tech Stack (Current Repo Composition)

- **Shell** (automation scripts)
- **HCL** (Terraform definitions)
- **Bicep** (Azure resource templating)

## Repository Structure

> Note: This is a suggested high-level structure based on the current `infra/` focus.

```text
iac-platform-hub-sample/
├── infra/                   # Core IaC assets (Terraform/Bicep/modules/env configs)
│   ├── terraform/           # Terraform root/modules/state backend definitions
│   ├── bicep/               # Bicep templates and parameter files
│   ├── scripts/             # Shell scripts for validate/plan/deploy workflows
│   └── environments/        # Environment-specific overlays (dev/test/prod)
├── .gitignore               # Ignore local/state/secrets/build artifacts
└── README.md                # Project overview and usage guidance
```

## What This “Test IaC Platform Hub” Demonstrates

This sample demonstrates how a platform team can use IaC to:
1. Provision Azure infrastructure in a consistent and repeatable way.
2. Separate reusable infrastructure modules from environment-specific values.
3. Introduce deployment automation (validation, planning, apply steps).
4. Manage Node.js app-related platform configuration (networking, app settings dependencies, identity/access integration, etc.) via codified infrastructure workflows.

## Typical Workflow

1. Author or update IaC templates (Terraform/Bicep).
2. Validate templates and policy/compliance checks.
3. Generate a deployment plan for a target environment.
4. Apply deployment to Azure.
5. Verify infrastructure outputs used by the Node.js app runtime/config.

## Next Recommended Enhancements

- Add CI pipeline for `fmt`, `validate`, and `plan`.
- Add environment-specific variable strategy (`dev`, `test`, `prod`).
- Add secure secret handling with Azure Key Vault.
- Add remote state backend and locking for Terraform.
- Add deployment runbooks and architecture diagram.
