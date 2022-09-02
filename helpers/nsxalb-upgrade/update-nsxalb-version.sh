#!/usr/bin/env bash

# Print usage of the script
function usage() {
  echo "Usage: $0 <TKG_MGMT_CLUSTER_NAME> <NSXBALB_CONTROLLER_VERSION>"
  echo "For example: $0 tkg-mgmt-cls '21.1.4'"
  exit 1
}

# Check if there are exactly 2 argument provided to the script
if [ $# -ne 2 ]
then
  usage
fi

# Get script directory
BASEDIR=$(dirname "$0")
echo "Base directory: $BASEDIR"

# TKG management cluster name environment variable
TKG_MGMT_CLUSTER_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
NSXBALB_CONTROLLER_VERSION=$2

# Set Tanzu context
tanzu login --server "$TKG_MGMT_CLUSTER_NAME" || exit 1

# Make sure the correct Tanzu context is set
if [[ $(tanzu cluster list --include-management-cluster -o json | jq -e '.[] | select (.roles[0]=="management")' | jq -r '.name') == "$TKG_MGMT_CLUSTER_NAME" ]]; then
  echo "Tanzu context $TKG_MGMT_CLUSTER_NAME has been set"
else
  echo "Failed to set Tanzu context"
  exit 1
fi

# Set kubectl context
K8S_CONTEXT="$TKG_MGMT_CLUSTER_NAME-admin@$TKG_MGMT_CLUSTER_NAME"
echo "Setting kubectl context"
kubectl config use-context "$K8S_CONTEXT" || exit 1

# Make sure the correct kubectl context is set
if [[ $(kubectl config current-context) == "$K8S_CONTEXT" ]]; then
  echo "kubectl context $K8S_CONTEXT has been set"
else
  echo "Failed to set kubectl context"
  exit 1
fi

# Update ako-operator values.yaml
echo "Patching AKO Operator config"
SECRET_NAME=$(echo "$TKG_MGMT_CLUSTER_NAME-ako-operator-addon")
VALUES_B64=$(kubectl get secret "$SECRET_NAME" -n tkg-system -o jsonpath='{.data.values\.yaml}' | base64 -d | sed "0,/^\([[:space:]]*avi_controller_version: *\).*/s//\1${NSXBALB_CONTROLLER_VERSION}/;" - | base64 -w 0)
kubectl patch secret "$SECRET_NAME" -n tkg-system --type='json' -p='[{"op" : "replace" ,"path" : "/data/values.yaml" ,"value" : '"$VALUES_B64"'}]'

# Update AKODeploymentConfig
echo "Patching AKODeploymentConfig resources"
for akodeploymentconfig in $(kubectl get akodeploymentconfigs.networking.tkg.tanzu.vmware.com -o name);
do
  echo "Patching resource '$akodeploymentconfig'"
  kubectl patch "$akodeploymentconfig" --type=merge --patch "
  spec:
    controllerVersion: ${NSXBALB_CONTROLLER_VERSION}
  "
done

# Reconcile packages
kctrl app kick -a ako-operator -n tkg-system -y --wait
kctrl app kick -a load-balancer-and-ingress-service -n tkg-system -y --wait
kctrl app kick -a tanzu-addons-manager -n tkg-system -y --wait

echo ""
echo "Done!"
exit 0