# TFE Provider Tests for StackWeaver Teams

This directory contains Terraform configuration files to test the StackWeaver teams API implementation using the `terraform-provider-tfe`.

## Prerequisites

1. **StackWeaver API running** (usually on `localhost:8080`)
2. **TFE Provider installed** (`terraform init` will download it)
3. **API Token** for authentication
4. **Test Organization** (default: "main")

## Setup

### 1. Get an API Token

You need an API token to authenticate with the StackWeaver API.

**Option A: Via UI (when available)**
1. Log in to StackWeaver UI
2. Go to Settings > API Tokens
3. Create a new token
4. Copy the token value

**Option B: Via API**

```bash
# First, get a JWT token by logging in via Zitadel
# Then create an API token:
curl -X POST http://localhost:8080/api/v2/tokens \
  -H 'Authorization: Bearer <your-jwt-token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "data": {
      "type": "tokens",
      "attributes": {
        "description": "Terraform Provider Test Token"
      }
    }
  }'
```

### 2. Configure Terraform

Create a `terraform.tfvars` file:

```hcl
tfe_hostname = "localhost:8080"
tfe_token    = "your-api-token-here"
organization = "main"
```

**OR** set environment variables:

```bash
export TF_VAR_tfe_hostname="localhost:8080"
export TF_VAR_tfe_token="your-api-token-here"
export TF_VAR_organization="main"
```

### 3. Initialize Terraform

```bash
cd stackweaver-tests/tfe-tests
terraform init
```

### 4. Test Teams Resource

```bash
# Plan
terraform plan

# Apply
terraform apply

# Verify (check outputs)
terraform output

# Destroy
terraform destroy
```

## Creating Test Users

StackWeaver uses Zitadel for user authentication. Users must be created in Zitadel, not via the StackWeaver API.

### Create Users in Zitadel

1. Access Zitadel admin console (usually `http://localhost:8080/ui/console`)
2. Go to **Users** > **Users**
3. Click **New User**
4. Enter:
   - Email: `test@example.com`
   - Name: `Test User`
   - Password (or use passwordless if configured)
5. Save the user

The user will be automatically created in StackWeaver on first login.

### Verify Users via API

```bash
# List organization members (requires admin token)
curl -X GET http://localhost:8080/api/v2/organizations/main/members \
  -H 'Authorization: Bearer <admin-token>'

# List teams
curl -X GET http://localhost:8080/api/v2/organizations/main/teams \
  -H 'Authorization: Bearer <admin-token>'
```

## Testing Steps

1. **Create a team via Terraform:**
   ```bash
   terraform apply
   ```

2. **Verify via API:**
   ```bash
   curl -X GET http://localhost:8080/api/v2/organizations/main/teams/test-team \
     -H 'Authorization: Bearer <admin-token>'
   ```

3. **Check Terraform state:**
   ```bash
   terraform show
   ```

4. **Update the team:**
   - Modify `main.tf`
   - Run `terraform plan` and `terraform apply`

5. **Destroy the team:**
   ```bash
   terraform destroy
   ```

## Troubleshooting

### "Authentication failed"
- Verify your API token is correct
- Check that the token hasn't expired
- Ensure you're using the correct hostname

### "Organization not found"
- Verify the organization name (default: "main")
- Check that you're a member of the organization
- Verify the organization exists via API

### "Team already exists"
- Check if a team with the same name already exists
- Delete existing team or use a different name
- Use `terraform import` if you want to manage an existing team

### "Insufficient permissions"
- Only organization admins can create/manage teams
- Verify your user has admin role in the organization
- Check organization membership via API

## API Verification

You can verify the implementation works by testing the API directly:

```bash
# List teams
curl -X GET http://localhost:8080/api/v2/organizations/main/teams \
  -H 'Authorization: Bearer <token>'

# Get a specific team
curl -X GET http://localhost:8080/api/v2/organizations/main/teams/test-team \
  -H 'Authorization: Bearer <token>'

# Create a team
curl -X POST http://localhost:8080/api/v2/organizations/main/teams \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "data": {
      "type": "teams",
      "attributes": {
        "name": "api-test-team",
        "description": "Created via API",
        "visibility": "organization"
      }
    }
  }'
```

