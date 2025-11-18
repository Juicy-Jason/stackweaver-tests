# Stackweaver tests

Stackweaver aims to be fully tfe compliant, meaning the tfe provider can be used just as in terraform entreprise.

## Workspace

Set the `TFE_TOKEN` and use [providers](providers.tf)

```bash
export TFE_TOKEN="<YOUR_TOKEN>"
```

```pwsh
$env:TFE_TOKEN="<YOUR_TOKEN>"
```

manually verify orgs: `curl -H "Authorization: Bearer $TOKEN" https://stack.truyens.pro/api/v2/organizations/default`