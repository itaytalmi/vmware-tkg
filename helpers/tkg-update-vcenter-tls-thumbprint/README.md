# Updating the TLS Thumbprint of your vCenter Server certificate in TKG

The `tkg-update-vcenter-tls-thumbprint.sh` shell script in this directory should be used when your vCenter server certificate has been replaced and you need to apply the new TLS thumbprint in TKG.

## Usage

1. Make sure the script is executable.

   ```bash
   chmod +x tkg-update-vcenter-tls-thumbprint.sh
   ```

2. Retrieve the new vCenter TLS thumbprint. The thumbprint must be exactly in this format: `26:3A:FF:3E:01:84:36:F5:BC:18:80:27:0E:14:59:AB:8E:1B:9E:53`.
   You can extract the thumbprint in this format using govc. For example:

   ```bash
   export GOVC_INSECURE=true
   export GOVC_URL=your_vcenter_fqdn
   export GOVC_USERNAME=your_vsphere_user
   export GOVC_PASSWORD=your_vsphere_password

   govc about.cert -thumbprint
   ```

3. Execute the script using the following syntax:

   ```bash
   ./tkg-update-vcenter-tls-thumbprint.sh <TKG_MGMT_CLUSTER_NAME> <VCENTER_TLS_THUMBPRINT>
   ```

   For example:

   ```bash
   ./tkg-update-vcenter-tls-thumbprint.sh tkg-mgmt-cls '26:3A:FF:3E:01:84:36:F5:BC:18:80:27:0E:14:59:AB:8E:1B:9E:53'
   ```

   > Make sure you specify the thumbprint inside the single quotes as shown above.

   Example output:

   ```text
   ✔  successfully logged in to management cluster using the kubeconfig tkg-mgmt-cls
   Checking for required plugins...
   All required plugins are already installed and up-to-date
   Tanzu context tkg-mgmt-cls has been set
   Setting kubectl context
   Switched to context "tkg-mgmt-cls-admin@tkg-mgmt-cls".
   kubectl context tkg-mgmt-cls-admin@tkg-mgmt-cls has been set
   Updating vCenter TLS thumbprint for workload cluster 'tkg-shared-services-cls'
   secret/tkg-shared-services-cls-vsphere-cpi-addon patched
   vspherecluster.infrastructure.cluster.x-k8s.io/tkg-shared-services-cls patched
   Updating vCenter TLS thumbprint for workload cluster 'tkg-win-wld-cls'
   secret/tkg-win-wld-cls-vsphere-cpi-addon patched
   vspherecluster.infrastructure.cluster.x-k8s.io/tkg-win-wld-cls patched
   Updating vCenter TLS thumbprint for workload cluster 'tkg-wld-cls'
   secret/tkg-wld-cls-vsphere-cpi-addon patched
   vspherecluster.infrastructure.cluster.x-k8s.io/tkg-wld-cls patched
   secret/tkg-mgmt-cls-vsphere-cpi-addon patched
   vspherecluster.infrastructure.cluster.x-k8s.io/tkg-mgmt-cls patched
   ```

    >The above will cause the CPI to reconcile on all clusters. Once CPI is reconciled, it will trust the new TLS thumbprint.