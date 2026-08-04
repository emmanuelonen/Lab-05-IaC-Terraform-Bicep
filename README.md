# Lab 5 — Infrastructure as Code (IaC) with Terraform & Bicep on Azure
### Declarative IaC · Remote State Architecture · Drift Detection · Full Lifecycle Management

| Field | Value |
|---|---|
| **Completed** | August 2026 |
| **Platform** | Terraform CLI v1.x · Azure CLI · Bicep CLI · Azure Cloud Shell |
| **Cost** | $0.00–$1.50 USD (Azure Free Credits — resources destroyed via `terraform destroy` immediately on completion) |
| **Time taken** | 3–4 hours across multiple sessions |
| **Cert alignment** | AZ-104 Azure Administrator · AZ-400 DevOps Solutions · HashiCorp Terraform Associate |
| **Prerequisites** | Lab 1 (Active Directory) · Lab 2 (Azure Networking) · Lab 3 (Azure Identity) · Lab 4 (Azure Monitor) |
| **Career relevance** | Cloud Engineer · Infrastructure Automation Engineer · DevOps Engineer · DevSecOps Engineer |

---

## The Business Problem This Lab Solves

Labs 1 through 4 built, secured, governed and monitored the enterprise Azure environment — through the Azure Portal, PowerShell and the Entra Admin Centre. Every resource was provisioned by hand. This approach has a name: **ClickOps.** And in production environments, ClickOps is an operational risk.

Manual, portal-driven deployments are unrepeatable. They lack version control. They cannot be peer-reviewed. They introduce configuration drift — the gradual divergence between what infrastructure should be and what it actually is. When a production region must be rebuilt after a failure, or a new environment must match existing security baselines, manual deployment takes days and risks missing critical configurations.

**Global Logistics & Enterprise Services** — whose infrastructure spans all five labs — received a mandate from the DevSecOps steering committee: eliminate ClickOps by codifying the entire Azure estate into declarative, version-controlled Infrastructure as Code.

This is the exact IaC architecture a Cloud Engineer or DevOps Engineer implements to operationalise enterprise Azure deployments at scale.

| Role | How this lab applies |
|---|---|
| **Cloud Engineer** | Writing modular Terraform HCL, managing remote state, executing the plan/apply lifecycle |
| **Infrastructure Automation Engineer** | Codifying enterprise networking, identity and storage into repeatable, version-controlled modules |
| **DevOps Engineer** | Integrating IaC into CI/CD pipelines, enforcing state locking, detecting and remediating drift |
| **DevSecOps Engineer** | Securing state files with encrypted remote backends, eliminating secrets from code, managing RBAC on state storage |

---

## IaC Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      DEVELOPER WORKSTATION                              │
│   VS Code · Git CLI · Terraform CLI v1.x · Azure CLI · Bicep CLI       │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ Azure Service Principal / OIDC Auth
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  TERRAFORM REMOTE STATE BACKEND                         │
│   rg-terraform-state-eastus                                             │
│   sttfstateprod57240 — Public Access: Blocked · TLS 1.2 · Encrypted    │
│   Container: tfstate │ State File: lab5.prod.terraform.tfstate          │
│   State Locking: Azure Blob Lease — concurrent writes blocked           │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ Declarative Plan & Apply Cycle
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│               AZURE INFRASTRUCTURE LANDING ZONE                         │
│               rg-iac-enterprise-prod-eastus                             │
│                                                                         │
│  ┌──────────────────────────┐       ┌────────────────────────────────┐  │
│  │     HUB NETWORKING       │◄─────►│       SPOKE NETWORKING         │  │
│  │   vnet-hub-prod (10.0)   │ Peer  │   vnet-spoke-prod (10.1)       │  │
│  │   GatewaySubnet          │       │   AppSubnet (NSG Applied)      │  │
│  │   ManagementSubnet       │       │   DataSubnet (PE + DNS)        │  │
│  └──────────────────────────┘       └────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────────┐       ┌────────────────────────────────┐  │
│  │   OBSERVABILITY & IAM    │       │    PaaS & SECURE STORAGE       │  │
│  │   Log Analytics (LAW)    │       │    Storage Account (Blob)      │  │
│  │   User-Assigned MI       │       │    Private Endpoint + DNS      │  │
│  └──────────────────────────┘       └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                  │ Azure-Native IaC (Parallel Track)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│               BICEP DEPLOYMENT                                          │
│   rg-bicep-enterprise-prod-eastus                                       │
│   main.bicep · main.bicepparam · az deployment sub what-if             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## What Was Built

- ✅ Secure Terraform Remote State backend provisioned — `rg-terraform-state-eastus`, storage account `sttfstateprod57240`, container `tfstate`
- ✅ Storage account hardened — public blob access disabled, TLS 1.2 enforced, blob encryption enabled
- ✅ Terraform workspace initialised in Azure Cloud Shell (Bash) — `terraform init` connecting to remote backend confirmed
- ✅ `terraform validate` executed — HCL syntax and resource references confirmed structurally sound
- ✅ `terraform plan -out=tfplan.binary` executed — deterministic binary execution plan compiled and persisted
- ✅ `terraform apply tfplan.binary` executed — **10 enterprise resources provisioned: Apply complete! Resources: 10 added, 0 changed, 0 destroyed**
- ✅ Resources deployed: Hub VNet, ManagementSubnet, GatewaySubnet, Spoke VNet, AppSubnet, DataSubnet, NSG with least-privilege rules, Log Analytics Workspace, User-Assigned Managed Identity, Storage Account
- ✅ State lock protection verified — concurrent `terraform plan` in second terminal returned `Error: Error acquiring the state lock`
- ✅ PowerShell parameter parsing issue identified and documented — shell switched to Bash for plan execution, demonstrating environment-level debugging
- ✅ Bicep module authored — `main.bicep` and `main.bicepparam` created; `az bicep build` compiled and validated
- ✅ `az deployment sub what-if` executed — pre-flight dry-run confirmed resource changes before commit
- ✅ `az deployment sub create` executed — Bicep deployment to Azure completed, provisioning state: **Succeeded**
- ✅ Configuration drift simulated — port 8080 NSG rule added manually via Azure Portal (ClickOps change)
- ✅ `terraform plan` re-executed — drift detected, unauthorised rule flagged for remediation
- ✅ `terraform destroy -auto-approve` executed — all 10 resources removed in reverse dependency order
- ✅ Bicep and remote state resource groups deleted — clean tear-down, **$0 residual cost confirmed**

---

## Architecture Decisions — Why Each Choice Was Made

| Decision | Rationale | Enterprise Relevance |
|---|---|---|
| **Remote State in Azure Blob over local state** | Local state files store sensitive outputs in plain text and prevent team collaboration. Azure Remote State with Blob Lease enforces concurrency control — two engineers cannot modify infrastructure simultaneously. | Demonstrates understanding of production-grade CI/CD pipelines and DevSecOps team dynamics — a baseline expectation in any enterprise IaC role. |
| **Terraform HCL over ARM Templates** | ARM templates are verbose JSON with no abstraction layer. Terraform provides declarative syntax, modular reuse, a plan phase that previews changes before execution, and multi-cloud ecosystem portability. | Hiring managers actively prioritise Terraform proficiency over legacy ARM template authoring for cloud engineering roles. |
| **Declarative IaC over PowerShell scripts** | Imperative scripts require custom state-checking logic to avoid duplicate resource creation. Declarative IaC calculates the delta between desired and actual state and applies only the difference. | Prevents duplicate resource provisioning, operational downtime and configuration drift in production environments — critical in regulated industries. |
| **Compiled binary plan (`-out=tfplan.binary`)** | A compiled plan guarantees that the exact changes inspected during review are the changes applied — not a recalculated plan that may differ if cloud state changed between approval and execution. | In enterprise change-managed environments the plan is the audit artefact. Applying the compiled binary ensures what was approved is precisely what was deployed. |
| **Azure Blob Lease for state locking** | Without locking, two concurrent `terraform apply` operations can corrupt the state file — a production-stopping failure requiring manual state surgery. Blob Lease is Azure's native locking mechanism requiring no additional tooling. | State file corruption is one of the most operationally damaging failure modes in IaC workflows. |
| **Bicep as complementary IaC track** | Bicep is Azure-native with zero external state overhead — Azure Resource Manager tracks deployment state natively. Demonstrating both Terraform and Bicep proves cross-ecosystem IaC proficiency. | Many Azure-first organisations standardise on Bicep for greenfield deployments while maintaining Terraform for multi-cloud environments. Knowing both is a genuine differentiator. |
| **Full `terraform destroy` on completion** | Demonstrating the complete lifecycle — provision, verify, drift-detect, destroy — proves IaC is understood as a lifecycle management tool, not just a provisioning mechanism. | Cost governance is an engineering discipline. Automated tear-down capability is expected in CI/CD pipelines for ephemeral environments. |

---

## Key Concepts Explained

### What is Infrastructure as Code?

Infrastructure as Code is the practice of defining, provisioning and managing cloud infrastructure through machine-readable configuration files rather than through manual processes or interactive interfaces. Instead of clicking through the Azure Portal to create a virtual network, a Cloud Engineer writes a declarative file describing the desired end state — and the IaC tool calculates and executes the steps required to achieve it. The configuration is stored in version control, reviewed in pull requests, tested in pipelines, and deployed automatically — giving infrastructure the same engineering rigour as application code.

### What is Terraform?

Terraform is HashiCorp's open-source IaC engine. It reads declarative HCL configuration files, queries the current state of cloud infrastructure, calculates the difference between desired and actual state, and executes the minimum changes required to reconcile them. Terraform is multi-cloud — the same workflow applies to Azure, AWS, GCP and dozens of other providers. Its three core lifecycle commands are `terraform plan` (preview changes), `terraform apply` (execute changes) and `terraform destroy` (remove all managed resources).

### What is Remote State?

When Terraform provisions infrastructure it writes a state file (`terraform.tfstate`) recording the mapping between configuration and real cloud resources. By default this file is stored locally — it can be accidentally deleted, it contains sensitive values in plain text, and multiple engineers cannot collaborate without risking state corruption. Remote state stores this file in a shared, encrypted, access-controlled backend — in this lab, an Azure Blob Storage container. Azure Blob Lease provides state locking: only one operation can hold the lock at a time, preventing concurrent modifications from corrupting the state.

### What is Bicep?

Azure Bicep is Microsoft's domain-specific language for Azure Resource Manager deployments. It is the Azure-native alternative to Terraform for Azure-only environments. Bicep transpiles to ARM JSON at deployment time and requires no external state file — Azure Resource Manager tracks deployment state natively. The `az deployment sub what-if` command provides Bicep's equivalent of `terraform plan` — a pre-flight dry run showing exactly what will change before execution.

### What is Configuration Drift?

Configuration drift is the divergence between infrastructure's defined state (the IaC code) and its actual state (what is running in the cloud). Drift occurs when changes are made outside the IaC pipeline — through the Azure Portal or emergency CLI commands — without being reflected in the code. Terraform detects drift automatically when `terraform plan` is run: any resource whose actual configuration differs from desired state is flagged for remediation. In this lab, drift was deliberately introduced by adding an NSG rule via the Portal and Terraform immediately detected the unauthorised modification.

---

## Terraform File Structure

```
Lab-05-Terraform-Azure/
├── backend.tf          # Remote state backend — Azure Storage Blob + provider config
├── main.tf             # Core resources — VNets, NSG, LAW, managed identity, storage
├── variables.tf        # Input variable declarations with types and descriptions
├── terraform.tfvars    # Variable values for the production environment
├── outputs.tf          # Output values — resource IDs, endpoints, workspace ID
└── bicep/
    ├── main.bicep      # Azure-native Bicep module — storage, private DNS
    └── main.bicepparam # Parameter file for environment-specific values
```

---

## Screenshot Evidence Index

| Screenshot | File | What It Proves |
|---|---|---|
| 1a | `1a-terraform-remote-backend-storage.jpeg` | Storage account `sttfstateprod57240` provisioned — public blob access disabled, `tfstate` container created |
| 2b | `2b-initial-terraform-environment-validation-powershell.jpeg` | `terraform init` and `terraform validate` in Azure Cloud Shell — PowerShell parsing issue identified and documented |
| 3a | `3a-terraform-apply-success.jpeg` | `terraform apply tfplan.binary` complete — 10 resources added, 0 changed, 0 destroyed |
| 4a | `4a-bicep-deployment-success.jpeg` | Bicep deployment via `az deployment sub create` — provisioning state: Succeeded |
| 5a | `5a-terraform-destroy-success.jpeg` | `terraform destroy -auto-approve` complete — all managed resources removed, $0 residual cost confirmed |

---

## Files in This Repository

| File | Contents |
|---|---|
| `terraform/backend.tf` | AzureRM provider configuration and Azure Blob remote state backend |
| `terraform/main.tf` | Core infrastructure — Hub VNet, Spoke VNet, NSG, LAW, managed identity, storage, private endpoint |
| `terraform/variables.tf` | Input variable declarations with type constraints and descriptions |
| `terraform/terraform.tfvars` | Production variable values |
| `terraform/outputs.tf` | Output definitions — resource IDs and endpoint values |
| `bicep/main.bicep` | Azure-native Bicep module — storage account and private DNS zone |
| `bicep/main.bicepparam` | Bicep parameter file for environment-specific values |
| `scripts/01-bootstrap-remote-state.ps1` | Azure CLI script to provision remote state storage infrastructure |
| `scripts/02-terraform-lifecycle.sh` | Full Terraform init → validate → plan → apply workflow in Bash |
| `scripts/03-deploy-bicep.sh` | Bicep what-if and deploy commands |
| `scripts/04-drift-and-destroy.sh` | Drift detection verification and full tear-down sequence |

---

## Verification Checklist

| Check | Command / Location | Expected Result |
|---|---|---|
| Remote state storage exists | `az group show --name rg-terraform-state-eastus` | Resource group — Succeeded |
| State file present in blob | Portal → Storage Account → Containers → `tfstate` | `lab5.prod.terraform.tfstate` visible |
| Public blob access disabled | Storage Account → Networking | Allow blob public access: **Disabled** |
| TLS 1.2 enforced | Storage Account → Configuration | Minimum TLS version: **TLS 1.2** |
| Infrastructure deployed | `az resource list --resource-group rg-iac-enterprise-prod-eastus --output table` | 10 resources listed |
| State lock enforced | Run concurrent `terraform plan` in second terminal | `Error: Error acquiring the state lock` |
| Bicep deployment succeeded | `az deployment sub show --name main` | Provisioning state: **Succeeded** |
| Drift detected | `terraform plan` after manual NSG portal edit | Plan shows 1 resource to modify or destroy |
| Clean tear-down complete | `az group list --output table` after destroy | `rg-iac-enterprise-prod-eastus` absent |

---

## On-Premises to Azure IaC Mapping

| On-Premises Concept | Azure IaC Equivalent | Enterprise Benefit |
|---|---|---|
| Manual server build sheets / runbooks | Terraform modules (`main.tf`) | Provisioning time reduced from days to minutes — repeatable, zero human error |
| Configuration audit / baseline drift checks | `terraform plan` + state file (`.tfstate`) | Continuous drift detection — unauthorised changes flagged automatically |
| Custom batch deployment scripts | Azure Bicep templates (`main.bicep`) | Native, zero-compilation ARM automation with day-zero resource type support |
| Change management documentation | `terraform plan` output + Git commit history | Every infrastructure change is reviewable, attributable and auditable |
| Configuration management database (CMDB) | Terraform state file | Real-time inventory of every managed resource with attributes and dependencies |
| Emergency change rollback | `terraform destroy` + `terraform apply` | Full environment reconstruction from code — disaster recovery in minutes |

---

## Lab Progression — Labs 1 Through 5

| | Lab 1 | Lab 2 | Lab 3 | Lab 4 | Lab 5 |
|---|---|---|---|---|---|
| **Focus** | Active Directory | Azure Networking | Azure Identity | Azure Monitor | Infrastructure as Code |
| **Method** | Portal / PowerShell | Portal / PowerShell | Portal / Graph SDK | Portal / KQL | Declarative code — zero ClickOps |
| **Repeatability** | Manual — unrepeatable | Manual — unrepeatable | Manual — unrepeatable | Manual — unrepeatable | `terraform apply` — fully repeatable |
| **Version control** | None | None | None | None | Git-tracked HCL + state file |
| **Drift detection** | None | None | None | None | `terraform plan` — detects immediately |
| **Audit trail** | None | None | None | Log Analytics | Git history + Terraform state |
| **Disaster recovery** | Hours to rebuild manually | Hours to rebuild manually | Hours to rebuild manually | Hours to rebuild manually | Minutes — single command from code |
| **Core output** | Identity boundary | Network boundary | Access governance | Observability | Immutable, repeatable infrastructure |

**Lab 5 is the retrospective answer to every lab before it.** Everything built manually in Labs 1–4 can be expressed as code, stored in version control, reviewed before deployment, and rebuilt from scratch in a single command. The enterprise estate is no longer dependent on institutional memory or manual runbooks — it lives in the repository.

---

## Interview Questions This Lab Prepares You For

**"What is the difference between Terraform and Bicep?"**
Terraform is a multi-cloud, vendor-neutral IaC engine using HCL. It manages its own state file externally — a remote backend like Azure Blob Storage is required for team use. It works across Azure, AWS, GCP and hundreds of providers. Bicep is Azure-native and state-free — Azure Resource Manager tracks deployment state internally. Both are declarative. Terraform is preferred in multi-cloud or cross-platform organisations; Bicep is preferred in Azure-first environments for its zero state management overhead and day-zero resource support.

**"How do you prevent two engineers from corrupting Terraform state simultaneously?"**
Remote state with state locking. Store the state file in an Azure Blob Storage container configured with Blob Lease. When any Terraform operation begins it acquires the lease — a lock. Any concurrent operation attempting to acquire the same lease receives `Error: Error acquiring the state lock` and is blocked until the first operation completes and releases the lock.

**"What happens if a `terraform apply` fails halfway through?"**
Terraform updates the remote state file sequentially as each resource operation completes. If the deployment fails halfway, the state file records all successfully created resources. Running `terraform apply` again calculates the state difference and provisions only the remaining uncreated resources — it does not recreate resources that already exist and match the desired configuration.

**"How do you handle secrets in Terraform on Azure?"**
Hardcoding credentials in `.tf` files is a critical security risk — secrets appear in the state file in plain text. The production pattern is to store secrets in Azure Key Vault and reference them dynamically using `data.azurerm_key_vault_secret` sources, or inject them at runtime via environment variables (`TF_VAR_admin_password`) passed through a secured CI/CD pipeline such as GitHub Actions or Azure DevOps — never stored in the repository or state file.

---

*Part of a structured cloud engineering portfolio — Lab 1: Active Directory | Lab 2: Azure Networking | Lab 3: Azure Identity | Lab 4: KQL & Azure Monitor | Lab 5: Terraform on Azure*

**Emmanuel Onen · Senior Systems Engineer · Cayman Islands**
*Certification path: AZ-900 → AZ-104 → AI-102 → AZ-400*
*GitHub: [github.com/emmanuelonen](https://github.com/emmanuelonen)*
