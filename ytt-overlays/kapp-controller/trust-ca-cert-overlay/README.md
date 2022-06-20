# Applying the CA Certificate Overlay for kapp-controller

- [Applying the CA Certificate Overlay for kapp-controller](#applying-the-ca-certificate-overlay-for-kapp-controller)
  - [Apply the Overlay Pre-Deployment - New Clusters](#apply-the-overlay-pre-deployment---new-clusters)
  - [Apply the Overlay Post-Deployment - Existing Clusters](#apply-the-overlay-post-deployment---existing-clusters)
    - [Prerequisites](#prerequisites)
    - [Usage Instructions](#usage-instructions)

Use the overlay in this directory to apply your CA certificate(s) to kapp-controller, so that kapp-controller can deploy packages from your private registry (e.g. Harbor).

You can either apply the overlay pre-deployment (the recommended approach, the overlay will apply on newly-deployed clusters) or post-deployment (the overlay will apply on existing clusters).

## Apply the Overlay Pre-Deployment - New Clusters

```bash
cp add_kapp-controller.yaml ~/.config/tanzu/tkg/providers/ytt/02_addons/kapp-controller
```

Put your CA certificate in the YTT customization directory.

```bash
vi  ~/.config/tanzu/tkg/providers/ytt/02_addons/kapp-controller/ca-cert.pem
```

## Apply the Overlay Post-Deployment - Existing Clusters

This can be done automatically using the `apply-overlay.sh` script in this directory.

### Prerequisites

- You must have the following installed:
  - Tanzu CLI
  - kubectl
  - jq
- You must have your TKG management cluster kubeconfig present.

### Usage Instructions

First, set your CA certificate(s) in the `trust-ca-cert-overlay.yaml` file.

Then, run the `apply-overlay.sh` script using the following syntax:

```bash
./apply-overlay.sh <TKG_MGMT_CLUSTER_NAME>
```

For example:

```bash
./apply-overlay.sh tkg-mgmt-cls
```

The script performs the following:

- Logs in to the specified management cluster using Tanzu CLI
- Switches the kubectl context to the specified management cluster
- Base64 encodes the `trust-ca-cert-overlay.yaml` file
- Loops through all workload clusters and patches the kapp-controller add-on secrets, setting the `data.overlay.yaml` key along with the Base64-encoded overlay (`trust-ca-cert-overlay.yaml`).

>The script is fully idempotent, and can be run in any state.

Example output:

```text
Base directory: .
✔  successfully logged in to management cluster using the kubeconfig tkg-mgmt-cls
Checking for required plugins...
All required plugins are already installed and up-to-date
Tanzu context tkg-mgmt-cls has been set
Setting kubectl context
Switched to context "tkg-mgmt-cls-admin@tkg-mgmt-cls".
kubectl context tkg-mgmt-cls-admin@tkg-mgmt-cls has been set
Applying overlay on workload cluster 'tkg-shared-services-cls'
secret/tkg-shared-services-cls-kapp-controller-addon patched
Applying overlay on workload cluster 'tkg-wld-cls-01'
secret/tkg-wld-cls-01-kapp-controller-addon patched
Applying overlay on workload cluster 'tkg-wld-cls-02'
secret/tkg-wld-cls-02-kapp-controller-addon patched
Done!

Note: make sure the kapp-controller packages are successfully reconciling after these changes.
It may take a few minutes for the reconciliation to complete.
Run 'kubectl get app -n default' to monitor the status of the packages
```

After executing the script, verify that the kapp-controller packages have been successfully reconciled for all workload clusters.

```bash
kubectl get app -n default
```

Example output:

```bash
NAME                                              DESCRIPTION           SINCE-DEPLOY   AGE
tkg-shared-services-cls-kapp-controller           Reconcile succeeded   61s            27h
tkg-wld-cls-01-kapp-controller                    Reconcile succeeded   35s            6h34m
tkg-wld-cls-02-kapp-controller                    Reconcile succeeded   44s            23h
```

Your CA certificate(s) are now trusted by kapp-controller.
