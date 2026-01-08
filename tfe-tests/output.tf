// outputs
output "team_id" {
  description = "The ID of the created team"
  value       = tfe_team.test_team.id
}

output "team_name" {
  description = "The name of the created team"
  value       = tfe_team.test_team.name
}

output "organization_membership_id" {
  description = "The ID of the created organization membership"
  value       = tfe_organization_membership.test_member.id
}

output "team_organization_member_id" {
  description = "The ID of the team organization member relationship"
  value       = tfe_team_organization_member.test_team_member.id
}

output "team_organization_members_ids" {
  description = "The IDs of the team organization members relationships"
  value       = tfe_team_organization_members.test_team_members.organization_membership_ids
}