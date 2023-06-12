#!/usr/bin/env bash

# Print usage of the script
function usage() {
  echo "Usage: $0 <TKG_MGMT_CLUSTER_NAME>"
  echo "For example: $0 it-tkg-mgmt-cls"
  exit 1
}

# Check if there is exactly 1 argument provided to the script
if [ $# -ne 1 ]
then
  usage
fi

# Get script directory
BASEDIR=$(dirname "$0")
echo "Base directory: $BASEDIR"

# TKG management cluster name environment variable
TKG_MGMT_CLUSTER_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')

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

# Base64-encode the updated Pinniped configuration file
PINNIPED_ADDON_VALUES="$BASEDIR/pinniped-addon-values.yaml"

echo "Base64-encoding the updated Pinniped configuration file"
B64_NEW_CONFIG=$(cat "$PINNIPED_ADDON_VALUES" | base64 -w 0)

# Patch the secret
echo "Patching Pinniped configuration on Kubernetes"
kubectl patch secret -n tkg-system "$TKG_MGMT_CLUSTER_NAME-pinniped-addon" --type='json' -p='[{"op" : "replace" ,"path" : "/data/values.yaml" ,"value" : '$B64_NEW_CONFIG'}]'

# Delete old deployments to make sure the new ones load the new configuration after reconciliation
echo "Cleaning up old Pinniped Kubernetes deployments"
kubectl delete deployment --all -n pinniped-supervisor --wait
kubectl delete job --all -n pinniped-supervisor --wait
kubectl delete ns tanzu-system-auth --wait

# Trigger reconciliation for the Pinniped package
echo "Reconciling the Pinniped package"
kctrl app kick -a pinniped -n tkg-system -y --wait

# Delete the post-deploy Pinniped job before the second reconciliation
kubectl delete job --all -n pinniped-supervisor --wait

# Trigger reconciliation for the Pinniped package
echo "Reconciling the Pinniped package"
kctrl app kick -a pinniped -n tkg-system -y --wait

# Cleanup Pinniped sessions and credentials
echo "Cleaning up old Pinniped sessions and credentials"
rm -rf ~/.config/tanzu/pinniped/*

# Cleanup temporary files
rm "$PINNIPED_ADDON_VALUES"

echo ""
echo "Done"
