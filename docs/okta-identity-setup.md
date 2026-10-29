# Okta Sign-In Setup

Use this guide when an organization wants Okta to control access to its customer-owned Mission Shield deployment.

## Create the application

1. In the organization's Okta Admin Console, create an **OIDC Web Application**.
2. Enable the authorization code flow.
3. Add the exact sign-in redirect URI: `https://api-host/v1/auth/callback`.
4. Assign the people or groups allowed to sign in.
5. Store the client secret in the organization's protected cloud secret store.

## Configure Mission Shield in the deployment form

```text
OIDC_PROVIDER_NAME=okta
OIDC_ISSUER_URL=https://<okta-domain>/oauth2/default
OIDC_CLIENT_ID=<application-client-id>
OIDC_CLIENT_SECRET=<secret-from-the-customer-secret-store>
OIDC_REDIRECT_URL=https://api-host/v1/auth/callback
```

The provider must return `email` and boolean `email_verified` claims for the `openid profile email` scopes. Mission Shield matches a pending invitation to that exact verified email. Provider groups do not grant Mission Shield roles; Workspace Owners manage roles inside Mission Shield.

The deployment form also asks for the organization name and first owner's email. Mission Shield creates the blank workspace during deployment and activates its first owner when Okta returns that exact verified email. No terminal bootstrap is required.

## Acceptance test

1. Use a test account with no real assessment information.
2. Confirm the invited, assigned Okta user can accept the invitation.
3. Confirm an unassigned user cannot sign in.
4. Confirm an account with a different email cannot accept the invitation.
5. Suspend the member in Mission Shield and confirm the existing session loses access.
6. Record the test date and operator in the deployment checklist.

References: [Okta redirect sign-in guide](https://developer.okta.com/docs/guides/sign-into-web-app-redirect/main/) and [Okta claims guidance](https://developer.okta.com/docs/concepts/oauth-claims/).
