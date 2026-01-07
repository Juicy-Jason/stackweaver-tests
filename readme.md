# StackWeaver Tests Repository

This repository contains test configurations for the StackWeaver platform.

## Contents

### Terraform
Root directory contains Terraform configuration files for testing the Terraform workspace integration.

- `main.tf` - Main Terraform configuration
- `providers.tf` - Provider configuration
- `variables.tf` - Input variables

### Ansible
The `ansible/` directory contains sample Ansible playbooks for testing the Ansible integration.

#### Playbooks

| Playbook | Description |
|----------|-------------|
| `ansible/site.yml` | Main entry point playbook (default) |
| `ansible/playbooks/hello-world.yml` | Simple localhost playbook for testing |
| `ansible/playbooks/deploy.yml` | Application deployment example |

#### Structure

```
ansible/
├── site.yml                    # Main playbook (default)
├── group_vars/
│   └── all.yml                 # Variables for all hosts
├── inventory/
│   └── hosts.ini               # Sample static inventory
├── playbooks/
│   ├── hello-world.yml         # Simple test playbook
│   └── deploy.yml              # Deployment playbook
└── roles/
    ├── common/
    │   └── tasks/main.yml      # Common system tasks
    └── webserver/
        ├── tasks/main.yml      # Nginx installation
        ├── handlers/main.yml   # Service handlers
        └── templates/
            ├── index.html.j2   # Web page template
            └── nginx.conf.j2   # Nginx config template
```

---

## Terraform Testing

Stackweaver aims to be fully TFE compliant, meaning the TFE provider can be used just as in Terraform Enterprise.

### Authentication

Stackweaver supports TFE token authentication. You can use either:
1. **Environment Variable** (Recommended): Set `TFE_TOKEN` environment variable
2. **In providers.tf**: Hardcode the token (not recommended for production)

#### Using Environment Variable (Recommended)

**Bash/Zsh:**
```bash
export TFE_TOKEN="tfe-xxx"
```

**PowerShell:**
```pwsh
$env:TFE_TOKEN="tfe-xxx"
```

**Windows CMD:**
```cmd
set TFE_TOKEN=tfe-xxx
```

#### Using providers.tf (Not Recommended)

You can also hardcode the token in `providers.tf`, but this is not recommended for production:

```hcl
terraform {
  backend "remote" {
    hostname     = "stack.truyens.pro"
    organization = "mike"
    token        = "tfe-xxx"
    workspaces {
      name = "test"
    }
  }
}
```

## Testing

### 1. Verify Organization Access

Test that your token can access the organization:

```bash
export TOKEN=""
curl -H "Authorization: Bearer $TOKEN" https://stack.truyens.pro/api/v2/organizations/mike
```

Expected response: JSON with organization data

### 2. Test Terraform Init

> [!NOTE]
> set `export TF_LOG=DEBUG` for full debug logging

```bash
# Set the token
export TFE_TOKEN=""

# Navigate to test directory
cd stackweaver-tests

# Initialize Terraform
terraform init
```

### 3. Verify Endpoints

Test individual endpoints:

```bash
export TOKEN=""

# Ping endpoint
curl -H "Authorization: Bearer $TOKEN" https://stack.truyens.pro/api/v2/ping
# Expected: "pong"

# Entitlement set
curl -H "Authorization: Bearer $TOKEN" https://stack.truyens.pro/api/v2/organizations/mike/entitlement-set
# Expected: JSON with entitlements

# List workspaces
curl -H "Authorization: Bearer $TOKEN" https://stack.truyens.pro/api/v2/organizations/mike/workspaces
# Expected: JSON array of workspaces
```

## Troubleshooting

### Error: "relation tfe_tokens does not exist"
This is expected - the system falls back to API keys lookup. The error can be ignored if authentication succeeds.

### Error: "Error creating workspace test: Bad Request"
This was fixed - the handler now supports JSON:API format that Terraform uses. Make sure you're using the latest code.

### Error: "Workspace not found"
The workspace doesn't exist yet. Terraform will create it automatically during `terraform init`.

## Terraform API Documentation

- **Organizations**: https://developer.hashicorp.com/terraform/enterprise/api-docs/organizations
- **Workspaces**: https://developer.hashicorp.com/terraform/enterprise/api-docs/workspaces
- **Runs**: https://developer.hashicorp.com/terraform/enterprise/api-docs/run
