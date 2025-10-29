Integration user setup

This folder contains instructions to create an integration user in a scratch org or to provision a real integration user in a non-scratch org. Do NOT commit secrets or private keys.

Steps (scratch org)

1. Deploy the permission set to the org (from repo root):

```bash
# push or deploy your source to the scratch org alias
sf project deploy start -u synckarma-scratch
```

2. Create a scratch org user (example uses `sf` to create a user in the scratch org):

```bash
# create a new user in the scratch org
sf org user create -u synckarma-scratch --setalias integration.user --definitionfile config/integration-user-def.json
```

3. Assign the permission set to the new user:

```bash
sf user permset assign -n Integration_User -u integration.user
```

Notes for non-scratch/production orgs

- For non-scratch orgs, create a dedicated integration user via Setup and assign the `Integration_User` permission set (deploy the permission set first). Consider using JWT auth for CI and store the private key in GitHub Secrets as `SF_JWT_KEY`.

```bash
# example: assign permission set to an existing username
sf user permset assign -n Integration_User -u integration@example.com
```

References

- Salesforce CLI docs: https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev
- PermissionSet metadata: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_permissionset.htm
