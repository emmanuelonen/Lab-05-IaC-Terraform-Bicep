# Lab 5 — Infrastructure as Code (IaC) with Terraform & Bicep on Azure

Declarative IaC · Remote State Architecture · Drift Detection · Automated Tear-Down

| Field | Value |
| :--- | :--- |
| Completed | August 2026 |
| Platform | Terraform CLI · Azure CLI · Bicep CLI · Azure Cloud Shell |
| Cost | $0.00–$1.50 USD (Azure Free Credits — resources destroyed via terraform destroy immediately on completion) |
| Time taken | 3–4 hours across multiple sessions |
| Cert alignment | AZ-104 Azure Administrator · AZ-400 DevOps Solutions · HashiCorp Terraform Associate |
| Prerequisites | Lab 1 (Active Directory) · Lab 2 (Azure Networking) · Lab 3 (Azure Identity) · Lab 4 (Azure Monitor) |
| Career relevance | Cloud Engineer · Infrastructure Automation Engineer · DevOps Engineer · DevSecOps Engineer |

---

## The Business Problem This Lab Solves

Labs 1 through 4 built, secured, and made observable an enterprise Azure environment — all through the Azure Portal. This approach has a name: ClickOps. And in production environments, ClickOps is an operational risk.

Manual, portal-driven deployments are unrepeatable. They lack version control. They cannot be peer-reviewed. They introduce configuration drift — the gradual divergence between what the infrastructure should be and what it actually is. When a production region must be rebuilt after a failure, or when a new environment must be provisioned to match existing standards, manual deployment takes days and risks missing security baseline configurations.

Global Logistics & Enterprise Services — whose infrastructure spans all five labs — has received a mandate from the DevSecOps steering committee: eliminate ClickOps by codifying the entire Azure infrastructure into declarative, version-controlled Infrastructure as Code.

This is the exact IaC architecture a Cloud Engineer or DevOps Engineer implements to operationalise enterprise Azure deployments.

| Role | How this lab applies |
| :--- | :--- |
| Cloud Engineer | Writing modular Terraform HCL, managing remote state, executing plan/apply lifecycle |
| Infrastructure Automation Engineer | Codifying enterprise networking, identity and storage into repeatable, version-controlled modules |
| DevOps Engineer | Integrating IaC into CI/CD pipelines, enforcing state locking, detecting and remediating drift |
| DevSecOps Engineer | Securing state files with encrypted remote backends, eliminating secrets from code, managing RBAC on state storage |

---

## IaC Pipeline Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKSTATION                           │
│   VS Code · Git CLI · Terraform CLI v1.x · Azure CLI · Bicep CLI        │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ (Azure Service Principal / OIDC Auth)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   TERRAFORM REMOTE STATE BACKEND                        │
│   rg-terraform-state-eastus                                             │
│   sttfstateprod57240 — Public Access Blocked · TLS 1.2 · Encrypted      │
│   Container: tfstate │ State File: lab5.prod.terraform.tfstate          │
│   State Locking: Azure Blob Lease — concurrent writes blocked           │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ (Declarative Plan & Apply Cycle)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│               AZURE INFRASTRUCTURE LANDING ZONE                         │
│                                                                         │
│   ┌────────────────────────┐           ┌──────────────────────────────┐ │
│   │     HUB NETWORKING     │◄──Peer───►│       SPOKE NETWORKING       │ │
│   │   vnet-hub-prod        │           │   vnet-spoke-prod            │ │
│   │   GatewaySubnet        │           │   AppSubnet (NSG Applied)    │ │
│   │   ManagementSubnet     │           │   DataSubnet (PE + DNS)      │ │
│   └────────────────────────┘           └──────────────────────────────┘ │
│                                                                         │
│   ┌────────────────────────┐           ┌──────────────────────────────┐ │
│   │  OBSERVABILITY & IAM   │           │     PaaS & SECURE STORAGE    │ │
│   │  Log Analytics (LAW)   │           │     Storage Account (Blob)   │ │
│   │  User-Assigned MI      │           │     Private Endpoint + DNS   │ │
│   └────────────────────────┘           └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

What Was Built

Secure Terraform Remote State backend provisioned — rg-terraform-state-eastus, storage account sttfstateprod57240, container tfstate.

Storage account hardened — public blob access disabled, TLS 1.2 enforced, blob encryption enabled.

Terraform workspace initialised in Azure Cloud Shell (Bash) — terraform init connecting to remote backend.

terraform validate executed — syntax and reference correctness confirmed before plan phase.

terraform plan -out=tfplan.binary executed — deterministic execution plan compiled and persisted.

terraform apply tfplan.binary executed — 10 enterprise resources provisioned in single automated deployment.

State lock verified — concurrent terraform plan in second terminal returned Error: Error acquiring the state lock.

Bicep module (main.bicep + main.bicepparam) authored — Azure-native DSL alternative deployment.

az bicep build --file main.bicep executed — Bicep compilation and ARM schema validation.

az deployment sub what-if executed — pre-flight dry-run validating resource changes before commit.

az deployment sub create executed — Bicep deployment to Azure completed successfully.

Configuration drift simulated — NSG port 8080 manually added via portal (ClickOps change).

terraform plan re-executed — drift detected, unauthorised rule flagged for remediation.

terraform destroy -auto-approve executed — all 10 Terraform-managed resources removed in dependency order.

Bicep and remote state resource groups deleted — clean teardown, $0 residual cost confirmed.

Architecture Decisions — Why Each Choice Was Made

Decision	Rationale	Enterprise Relevance
Remote State in Azure Blob over local state	Local state files store sensitive outputs in plain text and prevent team collaboration. Azure Remote State with Blob Lease enforces concurrency control via state locking — two engineers cannot modify infrastructure simultaneously.	Demonstrates understanding of production-grade CI/CD pipelines and DevSecOps team dynamics — a baseline expectation in any enterprise IaC role.
Terraform (HCL) over ARM Templates	ARM templates are verbose JSON with no abstraction. Terraform provides declarative syntax, modular reuse, a plan phase that previews changes before execution, and multi-cloud ecosystem adoption.	Hiring managers actively prioritise Terraform proficiency over legacy ARM template authoring for cloud engineering roles.
Declarative IaC over PowerShell scripts	Imperative scripts require custom state-checking logic to avoid duplicate resource creation. Declarative IaC calculates the delta between desired state and actual state — if a resource already exists and matches specification, it is not recreated.	Prevents duplicate resource provisioning, operational downtime and configuration drift in production environments — critical in FinServ and regulated industries.
Compiled binary plan (-out=tfplan.binary)	A compiled plan guarantees that the exact changes inspected during the review phase are the changes applied — not a recalculated plan that may differ if cloud state changed between review and execution.	In enterprise change-managed environments, the plan is the audit artefact. Applying the compiled binary ensures what was approved is what was deployed.
Azure Blob Lease for state locking over no locking	Without state locking, two concurrent terraform apply operations can corrupt the state file — a production-stopping failure that may require manual state surgery.	State file corruption is one of the most operationally damaging failure modes in IaC workflows. Blob Lease locking is Azure's native mechanism and requires no additional tooling.
Bicep as a complementary IaC layer	Bicep is Azure-native with zero external state file overhead — state is managed by Azure Resource Manager natively. Demonstrating both Terraform and Bicep proves cross-ecosystem IaC proficiency, which is increasingly required in Azure-centric roles.	Many Azure-first organisations standardise on Bicep for greenfield deployments while maintaining Terraform for multi-cloud or legacy environments. Knowing both is a genuine differentiator.
terraform destroy on completion	Lab environments left running accrue cost. Demonstrating the full lifecycle — provision, verify, drift-detect, destroy — proves understanding of IaC as a lifecycle management tool, not just a provisioning mechanism.	Cost governance is an engineering discipline in cloud environments. Automated tear-down capability is expected in CI/CD pipelines for ephemeral test environments.
Key Concepts Explained

What is Infrastructure as Code?

Infrastructure as Code is the practice of defining, provisioning and managing cloud infrastructure through machine-readable configuration files rather than through manual processes or interactive interfaces. Instead of clicking through the Azure Portal to create a virtual network, a Cloud Engineer writes a declarative file that describes the desired end state — and the IaC tool calculates and executes the steps required to achieve it. The configuration file is stored in version control, reviewed in pull requests, tested in pipelines, and deployed automatically — giving infrastructure the same engineering rigour as application code.

What is Terraform?

Terraform is HashiCorp's open-source Infrastructure as Code engine. It reads declarative HCL (HashiCorp Configuration Language) configuration files, queries the current state of cloud infrastructure, calculates the difference between desired and actual state, and executes the minimum set of changes required to reconcile them. Terraform is multi-cloud — the same tool and workflow patterns apply to Azure, AWS, GCP and dozens of other providers. Its three core lifecycle commands are terraform plan (preview changes), terraform apply (execute changes), and terraform destroy (remove all managed resources).

What is Remote State?

When Terraform provisions infrastructure, it writes a state file (terraform.tfstate) that records the mapping between your configuration and the real cloud resources it manages. By default this file is stored locally — which means it can be accidentally deleted, it contains secrets in plain text, and multiple engineers cannot collaborate without risking state corruption. Remote state stores this file in a shared, encrypted, access-controlled backend — in this lab, an Azure Blob Storage container. Azure Blob Lease provides state locking: only one operation can hold the state lock at a time, preventing concurrent modifications from corrupting the state.

What is Bicep?

Azure Bicep is Microsoft's domain-specific language for Azure Resource Manager (ARM) deployments. It is the direct Azure-native alternative to Terraform for Azure-only environments. Bicep transpiles to ARM JSON at deployment time and requires no external state file — Azure Resource Manager tracks the deployment state natively. Bicep is simpler to read and write than raw ARM JSON, has day-zero support for new Azure resource types, and integrates natively with Azure CLI and Azure DevOps. The az deployment sub what-if command provides Bicep's equivalent of terraform plan — a pre-flight dry run showing exactly what will change before execution.

What is Configuration Drift?

Configuration drift is the divergence between the infrastructure's defined state (the IaC code) and its actual state (what is running in the cloud). Drift occurs when changes are made outside of the IaC pipeline — through the Azure Portal, Azure CLI, or emergency changes — that are not reflected in the code. Terraform detects drift automatically when terraform plan is run: any resource whose actual configuration differs from the desired state is flagged for remediation. In this lab, drift was deliberately introduced by adding an NSG rule via the Portal, and Terraform immediately detected the unauthorised modification.

Terraform File Structure
Lab-05-Terraform-Azure/
├── backend.tf          # Remote state backend configuration — Azure Storage Blob
├── main.tf             # Core infrastructure resources — VNets, NSG, LAW, identity, storage
├── variables.tf        # Input variable declarations with types and descriptions
├── terraform.tfvars    # Variable values for the production environment
├── outputs.tf          # Output values exposed after apply (resource IDs, endpoints)
└── bicep/
    ├── main.bicep      # Azure-native Bicep module
    └── main.bicepparam # Parameter file for environment-specific values

Screenshot Evidence Index

Screenshot	File	What It Proves
1a	1a-terraform-remote-backend-storage.jpeg	Storage account sttfstateprod57240 provisioned — public blob access disabled, container tfstate created
2b	2b-initial-terraform-environment-validation-powershell.jpeg	terraform init and terraform validate executed in Azure Cloud Shell (PowerShell mode) — syntax confirmed
3a	3a-terraform-apply-success.jpeg	terraform apply tfplan.binary complete — 10 resources added, 0 changed, 0 destroyed
4a	4a-bicep-deployment-success.jpeg	Bicep deployment via az deployment sub create — provisioning state: Succeeded
5a	5a-terraform-destroy-success.jpeg	terraform destroy -auto-approve complete — all 10 managed resources removed, $0 residual cost

Files in This Repository

File	Contents
terraform/backend.tf	AzureRM provider configuration and Azure Blob remote state backend
terraform/main.tf	Core infrastructure — Hub VNet, Spoke VNet, NSG, LAW, managed identity, storage, private endpoint
terraform/variables.tf	Input variable declarations with type constraints
terraform/terraform.tfvars	Production variable values
terraform/outputs.tf	Output definitions — resource IDs and endpoint values
bicep/main.bicep	Azure-native Bicep module — storage account and private DNS zone
bicep/main.bicepparam	Bicep parameter file for environment-specific values
scripts/01-bootstrap-remote-state.ps1	Azure CLI script to provision remote state storage infrastructure
scripts/02-terraform-lifecycle.ps1	Full Terraform init → validate → plan → apply workflow
scripts/03-deploy-bicep.ps1	Bicep what-if and deploy commands
scripts/04-drift-and-destroy.ps1	Drift detection verification and full tear-down

Verification Checklist

Check	Command / Location	Expected Result
Remote state storage exists	az group show --name rg-terraform-state-eastus	Resource group exists — Succeeded
State file present in blob	Portal → Storage Account → Containers → tfstate	lab5.prod.terraform.tfstate visible
Public blob access disabled	Storage Account → Networking	Allow blob public access: Disabled
TLS 1.2 enforced	Storage Account → Configuration	Minimum TLS version: TLS 1.2
Infrastructure deployed	az resource list --resource-group rg-iac-enterprise-prod-eastus --output table	10 resources listed
State lock enforced	Run concurrent terraform plan in second terminal	Error: Error acquiring the state lock
Bicep deployment succeeded	az deployment sub show --name main	Provisioning state: Succeeded
Drift detected	terraform plan after manual NSG portal edit	Plan shows 1 resource to modify/destroy
Clean teardown	az group list --output table after destroy	rg-iac-enterprise-prod-eastus absent

On-Premises to Azure IaC Mapping

On-Premises Concept	Azure IaC Equivalent	Enterprise Benefit
Manual server build sheets / runbooks	Terraform modules (main.tf)	Provisioning time reduced from days to minutes — repeatable, zero-error
Configuration audit / baseline drift checks	terraform plan + state file (.tfstate)	Continuous drift detection — unauthorised changes flagged automatically
Custom batch deployment scripts	Azure Bicep templates (main.bicep)	Native, zero-compilation ARM automation — day-zero resource support
Change management documentation	terraform plan output + Git commit history	Every infrastructure change is reviewable, attributable and auditable
Configuration management database (CMDB)	Terraform state file	Real-time inventory of every managed resource with attributes and dependencies
Emergency change rollback	terraform destroy + terraform apply	Full environment reconstruction from code — disaster recovery in minutes

Lab 1 → Lab 2 → Lab 3 → Lab 4 → Lab 5 Progression

Metric	Lab 1	Lab 2	Lab 3	Lab 4	Lab 5
Focus Area	Active Directory	Azure Networking	Azure Identity	Azure Monitor	Infrastructure as Code
Method	Portal provisioning	Portal provisioning	Portal provisioning	Portal provisioning	Declarative code
Process	Manual step-by-step	Manual configuration	Manual policy creation	Manual DCR setup	terraform apply
Control	No version control	No version control	No version control	No version control	Git-tracked state
Efficiency	Unrepeatable	Unrepeatable	Unrepeatable	Unrepeatable	Fully repeatable
Recovery	Hours to rebuild	Hours to rebuild	Hours to rebuild	Hours to rebuild	Minutes to rebuild

Lab 5 is the retrospective answer to every lab before it: everything built manually in Labs 1–4 can be expressed as code, stored in version control, reviewed before deployment, and rebuilt from scratch in a single command.

Interview Questions This Lab Prepares You For

"What is the difference between Terraform and Bicep?"
Terraform is a multi-cloud, vendor-neutral IaC engine using HCL. It manages its own state file externally and works across Azure, AWS, GCP and hundreds of providers. Bicep is Azure-native and state-free — Azure Resource Manager tracks deployment state internally. Both are declarative. Terraform is preferred in multi-cloud or cross-platform organisations; Bicep is preferred in Azure-first environments for its zero state management overhead and day-zero resource support.

"How do you prevent two engineers from corrupting Terraform state simultaneously?"
Remote state with state locking. Store the state file in an Azure Blob Storage container configured with Blob Lease. When any Terraform operation begins, it acquires the lease — a lock. Any concurrent operation attempting to acquire the same lease receives Error: Error acquiring the state lock and is blocked until the first operation completes and releases the lock.

"What happens if a terraform apply fails halfway through?"
Terraform updates the remote state file sequentially as each resource operation completes. If the deployment fails halfway, the state file records all successfully created resources. Running terraform apply again calculates the state difference and provisions only the remaining uncreated resources — it does not recreate resources that already exist and match the desired configuration.

"How do you handle secrets in Terraform?"
Hardcoding credentials in .tf files is a critical security risk — secrets appear in the state file in plain text. The production pattern is to store secrets in Azure Key Vault and reference them dynamically using data.azurerm_key_vault_secret sources, or inject them at runtime via environment variables (TF_VAR_admin_password) passed through a secured CI/CD pipeline such as GitHub Actions or Azure DevOps, using pipeline secrets management — never stored in the repository.

Part of a structured cloud engineering portfolio — Lab 1: Active Directory | Lab 2: Azure Networking | Lab 3: Azure Identity | Lab 4: KQL & Azure Monitor | Lab 5: Terraform on Azure

Emmanuel Onen · Senior Systems Engineer · Cayman Islands
Certification path: AZ-900 → AZ-104 → AI-102 → AZ-400
GitHub: github.com/emmanuelonen
