# Test Teams Resource
# This file tests the teams API implementation

resource "tfe_team" "test_team" {
  name         = "test-team-tfe-provider"
  organization = var.organization
  visibility   = "organization"
}

resource "tfe_team" "test_team_1" {
  name         = "test-team-tfe-provider-1"
  organization = var.organization
  visibility   = "organization"
}

// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/workspace
data "tfe_workspace" "test" {
  name         = "stackweaver-tests-tfe-provider"
  organization = var.organization
}

// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_access#argument-reference
// Test 1: Fixed access level - read
# resource "tfe_team_access" "test_team_access_read" {
#   access       = "read" # Valid: read, plan, apply, write, admin, none
#   team_id      = tfe_team.test_team.id
#   workspace_id = data.tfe_workspace.test.id
# }


# resource "tfe_team_access" "test_team_access_custom" {
#   # When using permissions block, access will be automatically set to "custom" by the provider
#   # Do NOT set access explicitly when using permissions block
#   team_id      = tfe_team.test_team.id
#   workspace_id = data.tfe_workspace.test.id

#   permissions {
#     runs              = "apply"        # Valid: read, plan, apply
#     variables         = "write"        # Valid: none, read, write
#     state_versions    = "write"        # Valid: none, read, read-outputs, write
#     sentinel_mocks    = "read"         # Valid: none, read
#     workspace_locking = true           # Boolean
#     run_tasks         = true           # Boolean
#   }
# }

// Project Access

resource "tfe_project" "test" {
  name         = "myproject"
  organization = var.organization
}

resource "tfe_team_project_access" "custom" {
  access       = "custom"
  team_id      = tfe_team.test_team.id
  project_id   = tfe_project.test.id

  project_access {
    settings      = "read"
    teams         = "none"
    variable_sets = "write"
  }
  workspace_access {
    state_versions = "write"
    sentinel_mocks = "none"
    runs           = "apply"
    variables      = "write"
    create         = true
    locking        = true
    move           = false
    delete         = false
    run_tasks      = false
  }
}

// Organization Membership Tests
// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization_membership

// Test: Create an organization membership by email
// Note: The user must exist in Zitadel first
resource "tfe_organization_membership" "test_member" {
  email        = "test@vhco.pro"
  organization = var.organization
}

resource "tfe_organization_membership" "test_member_yassin_admin" {
  email        = "yassin@vhco.pro"
  organization = var.organization
}

// Team Organization Member Tests
// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_organization_member

// Test: Add a single organization membership to a team
// This adds the user (via their organization membership) to the team
resource "tfe_team_organization_member" "test_team_member" {
  team_id                    = tfe_team.test_team.id
  organization_membership_id = tfe_organization_membership.test_member.id
}

// Team Organization Members Tests
// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_organization_members

// Test: Add multiple organization memberships to a team at once
// Create additional membership for test1@vhco.pro
resource "tfe_organization_membership" "test_member_1" {
  email        = "test1@vhco.pro"
  organization = var.organization
}

// Add multiple members to the team at once
resource "tfe_team_organization_members" "test_team_members_1" {
  team_id = tfe_team.test_team_1.id

  organization_membership_ids = [
    tfe_organization_membership.test_member_1.id,
  ]
}