# Operations guide

Mission Shield runs in the organization's Azure account. The organization controls its identity system, database, backups, logs, updates, and removal.

## Daily checks

- Open the web address and confirm the sign-in page loads.
- Confirm an authorized user can sign in and sign out.
- Review Azure Container Apps and PostgreSQL health when users report an issue.
- Keep diagnostics free of assessment content, secrets, tokens, and unnecessary personal information.

## Backups and restore rehearsals

Azure PostgreSQL backup retention is selected during deployment. A backup is not considered proven until the organization has rehearsed a restore using fictional information and recorded the result. Use at least 14 days for a continuing pilot unless the organization's policy requires more.

## Updates

1. Read the Mission Shield release notes and security notices.
2. Export or confirm a current backup.
3. Test the new release in a non-production resource group.
4. Update the pinned API and web image digests in a reviewed copy of the deployment template.
5. Apply the reviewed deployment and complete sign-in, permissions, assessment, and export checks.

Do not replace digest-pinned images with floating tags such as `latest`.

## Rollback

Keep the previously accepted template and image digests. If an update fails acceptance, redeploy the last accepted template. A database schema change may require restoring the pre-update backup; follow the release notes before changing versions.

## Account recovery

Maintain at least two authorized administrators in the organization's identity provider. Mission Shield roles remain separate from provider access. Test the recovery path without disabling the only Workspace Owner.

## Export and closure

Before closure, create the required organization exports and store them in an approved location. Confirm retention obligations, then remove access and delete the Azure resource group. Verify that the resource group and its billable PostgreSQL server no longer appear.
