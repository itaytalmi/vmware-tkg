# Updating the Pinniped/Dex Configuration in TKG

The shell scripts in this directory can be used for updating the Pinniped/Dex package configuration in TKG.

## Usage

1. Make sure the scripts are executable.

   ```bash
   chmod +x *.sh
   ```

2. Execute the `01-get-pinniped-config.sh` script to get the current Pinniped config (and create a backup before modifying it). Use the following syntax:

   ```bash
   ./01-get-pinniped-config.sh <TKG_MGMT_CLUSTER_NAME>
   ```

   For example:

   ```bash
   ./01-get-pinniped-config.sh it-tkg-mgmt-cls
   ```

   Example output:

   ```text
   Base directory: .
   ✔  successfully logged in to management cluster using the kubeconfig it-tkg-mgmt-cls
   Checking for required plugins...
   All required plugins are already installed and up-to-date
   Tanzu context it-tkg-mgmt-cls has been set
   Setting kubectl context
   Switched to context "it-tkg-mgmt-cls-admin@it-tkg-mgmt-cls".
   kubectl context it-tkg-mgmt-cls-admin@it-tkg-mgmt-cls has been set
   Exporting current Pinniped configuration
   Creating a backup of the original Pinniped configuration

   Done
   ```

3. Modify the `pinniped-addon-values.yaml` YAML. Update any parameter you need to update.
   The most common parameters that are often modified in this manifest are under the `dex.config.ldap` section.

   For example:

   ```yaml
    ...
    dex:
    app: dex
    create_namespace: true
    namespace: tanzu-system-auth
    organization: vmware
    commonname: tkg-dex
    config:
        connector: ldap
        frontend:
          theme: tkg
        web:
          https: 0.0.0.0:5556
          tlsCert: /etc/dex/tls/tls.crt
          tlsKey: /etc/dex/tls/tls.key
        expiry:
          signingKeys: 90m
          idTokens: 5m
          authRequests: 90m
          deviceRequests: 5m
        logger:
          level: info
          format: json
        staticClients:
        - id: pinniped
          redirectURIs:
          - https://0.0.0.0/callback
          name: pinniped
          secret: dummyvalue
        ldap:
          host: cloudnativeapps.cloud:636
          insecureNoSSL: false
          startTLS: null
          rootCA: null
          rootCAData: LS0tLS1CRUdJTiBDRVJUSUZJQ0F....
          bindDN: CN=tkg-ldaps,OU=ServiceAccount,OU=cloudnativeapps,DC=cloudnativeapps,DC=cloud
          BIND_PW_ENV_VAR: YourP@ssw0rd!@#
          usernamePrompt: LDAP Username
          insecureSkipVerify: false
          userSearch:
          baseDN: DC=cloudnativeapps,DC=cloud
          filter: (objectClass=person)
          username: sAMAccountName
          idAttr: DN
          emailAttr: DN
          nameAttr: sAMAccountName
          scope: sub
          groupSearch:
          baseDN: DC=cloudnativeapps,DC=cloud
          filter: (objectClass=group)
          nameAttr: cn
          scope: sub
          userMatchers:
          - userAttr: DN
              groupAttr: member
   ```

4. Once done, execute the `02-update-pinniped-config.sh` script to apply the updated configuration and reconcile the Pinniped package. Use the following syntax:

   ```bash
   ./02-update-pinniped-config.sh <TKG_MGMT_CLUSTER_NAME>
   ```

   For example:

   ```bash
   ./02-update-pinniped-config.sh it-tkg-mgmt-cls
   ```

   Example output:

   ```text
   Base directory: .
   ✔  successfully logged in to management cluster using the kubeconfig it-tkg-mgmt-cls
   Checking for required plugins...
   All required plugins are already installed and up-to-date
   Tanzu context it-tkg-mgmt-cls has been set
   Setting kubectl context
   Switched to context "it-tkg-mgmt-cls-admin@it-tkg-mgmt-cls".
   kubectl context it-tkg-mgmt-cls-admin@it-tkg-mgmt-cls has been set
   Base64-encoding the updated Pinniped configuration file
   Patching Pinniped configuration on Kubernetes
   secret/it-tkg-mgmt-cls-pinniped-addon patched
   Cleaning up old Pinniped Kubernetes deployments
   deployment.apps "pinniped-supervisor" deleted
   job.batch "pinniped-post-deploy-job" deleted
   namespace "tanzu-system-auth" deleted
   ...
   job.batch "pinniped-post-deploy-job" deleted
   ...
   Cleaning up old Pinniped sessions and credentials

   Done
   ```
