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

## High-Level Deployment Plan — Terraform, Bicep, Ansible & Puppet
This section outlines the sequencing and responsibility of each tool in delivering the environment end-to-end, from bare Azure subscription to a running, monitored Node.js application.

## Phase 0 — Bootstrap (Azure CLI)
One-time, run manually or via a dedicated bootstrap pipeline — never re-applied by IaC to avoid circular dependency on its own state backend.
```
az group create --name rg-tfstate-shared --location australiaeast
az storage account create --name sttfstateplatformhub --resource-group rg-tfstate-shared --sku Standard_LRS
az storage container create --name tfstate --account-name sttfstateplatformhub
az keyvault create --name kv-nodeapp --resource-group rg-tfstate-shared --location australiaeast
```

## Phase 1 — Golden Image (Packer / Azure Image Builder)
Runs on a schedule or when the app/OS baseline changes — independent of environment deploys.
```
packer build -var-file=envs/prod.pkrvars.hcl packer/nodeapp-image.pkr.hcl
```
## Phase 2 — Infrastructure Provisioning (Terraform or Bicep)
**Choose one tool as the source of truth per environment** — do not run both against the same resource group.

## Terraform path
```
cd infra/terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Bicep path
```
az deployment sub what-if \
  --location australiaeast --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/envs/dev.bicepparam

az deployment sub create \
  --location australiaeast --name deploy-nodeapp-dev \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/envs/dev.bicepparam
  ```

## Phase 3 — Configuration Management (Ansible or Puppet)
Runs **after** infrastructure exists, targeting the newly provisioned VMSS instances. Handles anything that shouldn't require a full image rebuild — app version pinning, environment-specific settings, feature flags, secret references.

## Ansible path
```
# Generate dynamic inventory from live VMSS instances
az vmss nic list --resource-group rg-nodeapp-dev --vmss-name vmss-nodeapp \
  --query "[].ipConfigurations[0].privateIPAddress" -o tsv > inventory/dev/hosts.ini

ansible-playbook -i inventory/dev/hosts.yml playbooks/nodeapp.yml --check --diff   # dry-run first
ansible-playbook -i inventory/dev/hosts.yml playbooks/nodeapp.yml                 # apply
```

## Puppet path
```
# Nodes self-register with the Puppet master via customData at boot
puppet job run --nodes vmss-nodeapp* --environment dev --noop   # dry-run first
puppet job run --nodes vmss-nodeapp* --environment dev          # apply
```

## Phase 4 — Validation & Cutover
```
# Confirm VMSS health and zone distribution
az vmss list-instances --resource-group rg-nodeapp-dev --name vmss-nodeapp -o table

# Confirm App Gateway backend health
az network application-gateway show-backend-health \
  --resource-group rg-nodeapp-dev --name appgw-nodeapp-dev

# Confirm Front Door origin health
az afd origin list --profile-name fd-nodeapp-dev --resource-group rg-nodeapp-dev --origin-group-name og-appgw-dev -o table

# Confirm monitoring/alerts are wired
az monitor metrics alert list --resource-group rg-nodeapp-dev -o table
```
Only after health checks pass does traffic get cut over (DNS/Front Door routing) to the new environment. This layered plan ensures every environment is built from the same reproducible sequence — infra and configuration are never hand-applied, and disaster recovery is simply re-running Phases 1–4 against a new region or resource group.