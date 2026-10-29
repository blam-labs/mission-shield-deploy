# Mission Shield deployment

Deploy Mission Shield into an Azure subscription owned and operated by your organization. Blam Labs publishes the software and deployment template, but cannot access the resulting workspace, identity provider, database, backups, or assessment information.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fblam-labs%2Fmission-shield-deploy%2Fmain%2Fazure%2Fmain.json)

> **Private pilot:** Mission Shield `0.2.0-rc.8` is a prerelease intended for a limited, customer-owned pilot. Use fictional or non-sensitive information until your organization completes its own security, privacy, backup, and recovery review.

## Before you deploy

You need:

- An Azure subscription where you may create resources.
- A new or empty Azure resource group.
- A single-tenant Microsoft Entra app registration or an Okta OIDC web application.
- The identity application's client ID and client secret.
- A strong PostgreSQL administrator password.
- The first Workspace Owner's email address. Entra also requires that person's User Object ID.

Read the [Microsoft Entra setup](docs/entra-identity-setup.md) or [Okta setup](docs/okta-identity-setup.md) before opening the deployment form.

## What Azure creates

- One Azure Container Apps environment.
- One web container app and one API container app, both able to scale to zero when idle.
- One Azure Database for PostgreSQL Flexible Server.
- Optional database-storage email alerts when an operations address is supplied.

The release images are pinned by immutable digest. Deploying the template cannot silently substitute another image under the same version tag.

## Cost boundary

Azure shows an estimate before deployment. The PostgreSQL server continues billing while the resource group exists, even when the container apps have scaled to zero. Region, database size, retention, network traffic, and usage affect the total. Review the estimate with the Azure Pricing Calculator and delete the resource group when an evaluation ends.

## Guided deployment

1. Select **Deploy to Azure** above and sign in to the organization's Azure account.
2. Choose the subscription and a new or empty resource group.
3. Choose a supported region and enter a short lowercase resource prefix.
4. Enter the identity, organization, first-owner, and database values.
5. Keep `Standard_B2s` unless Azure confirms `Standard_B1ms` is supported in the selected region.
6. Review the generated resources and estimated cost, then select **Create**.
7. When Azure finishes, open **Outputs** and copy the web address and exact OIDC callback address.
8. Add that callback address to the Entra or Okta application.
9. Open the web address and sign in as the named first owner.
10. Complete the [operator checklist](docs/operator-checklist.md) before entering organizational information.

## Operate, update, and remove

The organization is responsible for identity access, HTTPS, secrets, backups, monitoring, updates, recovery, exports, and closure. Use the [operations guide](docs/operations.md) and retain a completed operator checklist.

To stop all evaluation charges, export only what the organization intends to retain, then delete the complete Azure resource group in the Azure portal. Confirm that the resource group no longer appears.

## Contents of this repository

This repository intentionally contains only the public deployment template and operator documentation. Mission Shield application source code and customer data are not included.

- `azure/main.json` — portal-ready Azure Resource Manager template.
- `azure/main.bicep` — readable source for the generated template.
- `docs/` — identity and operations guidance.

## Security

Do not commit secrets, tokens, database passwords, exports, backups, or organization information to this repository. Report suspected vulnerabilities privately through the security reporting channel described in [SECURITY.md](SECURITY.md).

Mission Shield is licensed under the Apache License 2.0. Product names and marks remain subject to [TRADEMARKS.md](TRADEMARKS.md).
