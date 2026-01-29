resource "tfe_organization" "test-organization" {
  name  = "stackweaver-tests-tfe-provider"
  email = "admin@zitadel.localhost"
}

resource "tfe_agent_pool" "test-agent-pool" {
  name         = "my-agent-pool-name"
  organization = "main"
  organization_scoped = true
}

data "tfe_project" "default-project" {
  name         = "default"
  organization = "main"
}

resource "tfe_agent_pool_allowed_projects" "allowed_projects" {
  agent_pool_id         = tfe_agent_pool.test-agent-pool.id
  allowed_project_ids   = [data.tfe_project.default-project.id]
}

# resource "tfe_agent_pool_allowed_workspaces" "allowed_workspaces" {
#   agent_pool_id         = tfe_agent_pool.test-agent-pool.id
#   allowed_workspace_ids = [data.tfe_workspace.test-workspace.id]
# }