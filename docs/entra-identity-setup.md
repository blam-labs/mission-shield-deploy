# Microsoft Entra Sign-In Setup

Use this guide when an organization wants Microsoft Entra ID to control access to its customer-owned Mission Shield deployment.

## Create the application

1. In the organization's Microsoft Entra admin center, create a new app registration.
2. Choose **Accounts in this organizational directory only**. Mission Shield requires a single-tenant issuer.
3. Add a **Web** redirect URI using the exact public API address: `https://api-host/v1/auth/callback`.
4. Create a client secret and place it in the organization's protected cloud secret store. Do not put it in source control or a container image.
5. Record the Application (client) ID and Directory (tenant) ID.

## Configure Mission Shield in the Azure form

Enter these values in the customer-owned Azure deployment form:

```text
OIDC_PROVIDER_NAME=entra
OIDC_ISSUER_URL=https://login.microsoftonline.com/<tenant-id>/v2.0
OIDC_CLIENT_ID=<application-client-id>
OIDC_CLIENT_SECRET=<secret-from-the-customer-secret-store>
OIDC_REDIRECT_URL=https://api-host/v1/auth/callback
```

The same form asks for the organization name, first owner's email, and first owner's Entra User Object ID. Mission Shield creates the blank workspace during deployment. When that exact person signs in for the first time, the workspace owner account is activated automatically.

A `common`, `organizations`, or `consumers` issuer is intentionally rejected because invitations are bound to one customer tenant.

## Invite people safely

For each invitation, the Workspace Owner enters:

- The person's email address, used for contact and displaying the invitation.
- The person's **User Object ID**, copied from that user's Entra profile.

Mission Shield authorizes the invitation using the immutable tenant ID and User Object ID claims. It does not use a mutable Entra email address as authorization authority. If the person's email changes later, their established external identity remains the same.

The first owner uses the same tenant-and-object-ID rule. No terminal bootstrap or private invitation link is required.

## Acceptance test

1. Use a test user with no real assessment information.
2. Confirm the assigned Entra user can accept the invitation.
3. Confirm another user in the same tenant cannot accept it.
4. Confirm a user from another tenant cannot accept it.
5. Suspend the member in Mission Shield and confirm the existing session loses access.
6. Record the test date and operator in the deployment checklist.

References: [Microsoft redirect URI guidance](https://learn.microsoft.com/entra/identity-platform/how-to-add-redirect-uri) and [Microsoft ID token claims reference](https://learn.microsoft.com/en-us/entra/identity-platform/id-token-claims-reference).
