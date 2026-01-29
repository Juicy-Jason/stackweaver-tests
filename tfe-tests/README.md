# TFE Provider Tests for StackWeaver Teams

This directory contains Terraform configuration files to test the StackWeaver teams API implementation using the `terraform-provider-tfe`.

```sh
git add . && git commit -am 'chore: testing provider' && git push origin main
```

## Prerequisites

1. **StackWeaver API running** (usually on `localhost:8022`)
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
curl -X POST http://localhost:8022/api/v2/tokens \
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
tfe_hostname = "localhost:8022"
tfe_token    = "your-api-token-here"
organization = "main"
```

**OR** set environment variables:

```bash
export TF_VAR_tfe_hostname="localhost:8022"
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

The test resources use the following test users:
- `test@vhco.pro`
- `test1@vhco.pro`

1. Access Zitadel admin console (usually `http://localhost:8080/ui/console`)
2. Go to **Users** > **Users**
3. Create the test users:
   - **User 1:**
     - Email: `test@vhco.pro`
     - Name: `Test User`
     - Password (or use passwordless if configured)
   - **User 2:**
     - Email: `test1@vhco.pro`
     - Name: `Test User 1`
     - Password (or use passwordless if configured)
4. Save both users

**IMPORTANT:** Users will be automatically created in StackWeaver on first login. You **must** have the test users log in at least once before creating organization memberships via Terraform.

**To ensure users exist:**
1. Log in as `test@vhco.pro` at least once (via the StackWeaver UI or API)
2. Log in as `test1@vhco.pro` at least once (via the StackWeaver UI or API)
3. Then run `terraform apply` to create organization memberships

### Verify Users via API

```bash
# List organization memberships (requires admin token)
curl -X GET http://localhost:8022/api/v2/organizations/main/organization-memberships \
  -H 'Authorization: Bearer <admin-token>'

# List teams
curl -X GET http://localhost:8022/api/v2/organizations/main/teams \
  -H 'Authorization: Bearer <admin-token>'
```

## Testing Steps

1. **Create test users in Zitadel:**
   - Create users with emails: `test@vhco.pro` and `test1@vhco.pro`
   - Ensure both users have logged in at least once to be created in StackWeaver

2. **Create resources via Terraform:**
   ```bash
   terraform apply
   ```

3. **Verify via API:**
   ```bash
   # Check organization memberships
   curl -X GET http://localhost:8022/api/v2/organizations/main/organization-memberships \
     -H 'Authorization: Bearer <admin-token>'
   
   # Check team members
   curl -X GET http://localhost:8022/api/v2/teams/<team-id>?include=organization-memberships \
     -H 'Authorization: Bearer <admin-token>'
   ```

4. **Check Terraform state:**
   ```bash
   terraform show
   terraform output
   ```

5. **Update resources:**
   - Modify `main.tf`
   - Run `terraform plan` and `terraform apply`

6. **Destroy resources:**
   ```bash
   terraform destroy
   ```

## Test Resources

The `main.tf` file includes test resources for:

1. **`tfe_organization_membership.test_member`** - Adds `test@vhco.pro` to the organization
2. **`tfe_team_organization_member.test_team_member`** - Adds `test@vhco.pro` (via organization membership) to the test team
3. **`tfe_organization_membership.test_member_2`** - Adds `test1@vhco.pro` to the organization
4. **`tfe_team_organization_members.test_team_members`** - Adds `test1@vhco.pro` (via organization membership) to the test team

**Test Users:**
- `test@vhco.pro` - Used for single membership and team member tests
- `test1@vhco.pro` - Used for multiple memberships test

**IMPORTANT - Prerequisites:**
Before running `terraform apply`, you **MUST** ensure:
1. ✅ Both test users (`test@vhco.pro` and `test1@vhco.pro`) exist in Zitadel
2. ✅ **Both users have logged in at least once** - This is critical! Users are only created in StackWeaver when they log in for the first time
3. ✅ You have the necessary permissions to create organization memberships and manage teams

**If you see "User with this email not found" errors:**
- The user hasn't logged in yet
- Have the user log in via the StackWeaver UI or API
- Then retry `terraform apply`

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
curl -X GET http://localhost:8022/api/v2/organizations/main/teams \
  -H 'Authorization: Bearer <token>'

# Get a specific team
curl -X GET http://localhost:8022/api/v2/organizations/main/teams/test-team \
  -H 'Authorization: Bearer <token>'

# Create a team
curl -X POST http://localhost:8022/api/v2/organizations/main/teams \
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





