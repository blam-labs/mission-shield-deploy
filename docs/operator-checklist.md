# Mission Shield operator checklist

Complete this checklist with fictional information before approving organizational use.

## Ownership

- [ ] The Azure subscription and resource group belong to the organization.
- [ ] A role-managed operations contact is recorded.
- [ ] The organization understands that Blam Labs cannot access or administer this environment.
- [ ] The Azure estimate and ongoing PostgreSQL cost have been reviewed.

## Identity and access

- [ ] The OIDC application is single-tenant and belongs to the organization.
- [ ] The exact API callback URL from deployment outputs is registered.
- [ ] The first Workspace Owner can sign in and sign out.
- [ ] An unauthorized account cannot enter the workspace.
- [ ] A suspended Mission Shield member loses access.
- [ ] At least two authorized administrators can recover access.

## Information boundary

- [ ] Staff understand that Mission Shield is not a case-management or beneficiary-record system.
- [ ] Evidence guidance discourages unnecessary personal information and secrets.
- [ ] The organization has documented retention and deletion expectations.

## Backup and recovery

- [ ] PostgreSQL retention matches the organization's pilot plan.
- [ ] A restore rehearsal has been completed with fictional information.
- [ ] The restore date, operator, outcome, and recovery time are recorded.
- [ ] Exports are stored only in an approved location.

## Operations

- [ ] Health and sign-in checks pass.
- [ ] The update procedure has been reviewed.
- [ ] The rollback path has been reviewed.
- [ ] The organization knows how to export and close a workspace.
- [ ] The organization knows that deleting the resource group stops the Azure evaluation resources and charges.

## Approval record

Record the date, Mission Shield version, deployment name, approver, and any accepted limitations in the organization's change or risk record.
