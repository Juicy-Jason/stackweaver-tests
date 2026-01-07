# Test Teams Resource
# This file tests the teams API implementation

resource "tfe_team" "test_team" {
  name         = "test-team"
  organization = var.organization
  visibility   = "organization"
}

// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/workspace
data "tfe_workspace" "test" {
  name         = "stackweaver-tfe-tests"
  organization = var.organization
}

// https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_access#argument-reference
// Test 1: Fixed access level - read
resource "tfe_team_access" "test_team_access_read" {
  access       = "read" # Valid: read, plan, apply, write, admin, none
  team_id      = tfe_team.test_team.id
  workspace_id = data.tfe_workspace.test.id
}

/*
resource "tfe_team_access" "test_team_access_custom" {
  team_id      = tfe_team.test_team_custom.id
  workspace_id = data.tfe_workspace.test.id

  permissions {
    runs              = "apply"        # Valid: read, plan, apply
    variables         = "write"        # Valid: none, read, write
    state_versions    = "write"        # Valid: none, read, read-outputs, write
    sentinel_mocks    = "read"         # Valid: none, read
    workspace_locking = true           # Boolean
    run_tasks         = true           # Boolean
  }
}
*/