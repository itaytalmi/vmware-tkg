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
if [[ $(tanzu cluster list -n tkg-system --include-management-cluster -o json | jq -e '.[] | select (.roles[0]=="management")' | jq -r '.name') == "$TKG_MGMT_CLUSTER_NAME" ]]; then
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

# Export Pinniped configuration
PINNIPED_ADDON_VALUES="$BASEDIR/pinniped-addon-values.yaml"
echo "Exporting current Pinniped configuration"
kubectl get secret -n tkg-system "$TKG_MGMT_CLUSTER_NAME-pinniped-package" -o jsonpath='{.data.values\.yaml}' | base64 -d > "$PINNIPED_ADDON_VALUES" || exit 1

# Create a backup of the original Pinniped configuration
echo "Creating a backup of the original Pinniped configuration"
cp "$PINNIPED_ADDON_VALUES" "$PINNIPED_ADDON_VALUES.orig_bak_$(date +%s)"

echo ""
echo "Done"