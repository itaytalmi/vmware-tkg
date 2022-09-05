# Upgrading NSX ALB in TKG

- [Upgrading NSX ALB in TKG](#upgrading-nsx-alb-in-tkg)
  - [Upgrade the NSX ALB Controllers and Service Engines](#upgrade-the-nsx-alb-controllers-and-service-engines)
  - [Update TKG Configuration](#update-tkg-configuration)

This procedure assumes that you are upgrading NSX ALB from version 20.x.x to 21.x.x for TKG.
However, the upgrade process is quite similar if you're uprading or patching any other version of NSX ALB.

## Upgrade the NSX ALB Controllers and Service Engines

First, obtain the upgrade package. You can download the files from <https://portal.avipulse.vmware.com/software/vantage>.

Login to any of the NSX ALB controllers, navigate to `Administration` > `Controller` > `Software` and click on `Upload From Computer`, then select your upgrade file, which is typically a `.pkg` file (e.g. `controller-21.1.4-2p3-9009.pkg`). Then wait for the upload to complete.

Navigate to `Administration` > `Controller` > `System Update`, select the new version you have just uploaded at the bottom and click `Upgrade`. In the upgrade dialog, make sure the `Upgrade All Service Engine Groups` option is selected and leave the defaults, then click `Continue`. Click `Confirm` in the second dialog if prompted. Then wait for the upgrade to complete.

Once the upgrade completes, navigate to `Administration` > `Controller` > `Nodes` and make sure all nodes are in the `Active` state.
Then navigate to `Administration` > `Controller` > `Software` and make sure there is no upgrade task in progress. This indicates that the upgrade has been completed.

## Update TKG Configuration

Since the NSX ALB controller version has changed, you must update the AKO Operator as well as the AKODeploymentConfig resources in TKG.
You can use the `tkg-update-nsxalb-version.sh` shell script in this directory to do so.
Execute the script using the following syntax:

```bash
./tkg-update-nsxalb-version.sh <TKG_MGMT_CLUSTER_NAME> <NSXBALB_CONTROLLER_VERSION>
```

For example:

```bash
./tkg-update-nsxalb-version.sh tkg-mgmt-cls '21.1.4'
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
Patching AKO Operator config
secret/it-tkg-mgmt-cls-ako-operator-addon patched
Patching AKODeploymentConfig resources
Patching resource 'akodeploymentconfig.networking.tkg.tanzu.vmware.com/install-ako-for-all'
akodeploymentconfig.networking.tkg.tanzu.vmware.com/install-ako-for-all patched
Patching resource 'akodeploymentconfig.networking.tkg.tanzu.vmware.com/install-ako-for-management-cluster'
akodeploymentconfig.networking.tkg.tanzu.vmware.com/install-ako-for-management-cluster patched

Done!
```

>**Note:** for new TKG management clusters, make sure you set the `AVI_CONTROLLER_VERSION` parameter to the NSX ALB controller version in your cluster config. For example: `AVI_CONTROLLER_VERSION: 21.1.4`.
