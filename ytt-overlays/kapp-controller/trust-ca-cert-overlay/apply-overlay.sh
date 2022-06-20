#!/usr/bin/env bash

# Print usage of the script
function usage() {
  echo "Usage: $0 <TKG_MGMT_CLUSTER_NAME>"
  echo "For example: $0 tkg-mgmt-cls"
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

# Base64-encode the overlay file content
OVERLAY_B64=$(cat "$BASEDIR/trust-ca-cert-overlay.yaml" | base64 -w 0)

# Loop through the workload clusters and add the overlay to the kapp-controller add-on secret
for workload_cluster in $(tanzu cluster list -o json | jq -r '.[].name')
do
    echo "Applying overlay on workload cluster '$workload_cluster'"

    # Build secret name
    SECRET_NAME=$(echo "$workload_cluster-kapp-controller-addon")

    # Make sure the secret exists. Skip if it doesn't
    if [[ $(kubectl get secret "$SECRET_NAME" -n default --no-headers | wc -l) == "1" ]]; then
        kubectl patch secret "$SECRET_NAME" -n default --type='json' -p='[{"op" : "replace" ,"path" : "/data/overlays.yaml" ,"value" : '"$OVERLAY_B64"'}]'
    else
        echo "Secret '$SECRET_NAME' could not be found. Skipping..."
    fi
done

echo "Done!"
echo ""
echo "Note: make sure the kapp-controller packages are successfully reconciling after these changes."
echo "It may take a few minutes for the reconciliation to complete."
echo "Run 'kubectl get app -n default' to monitor the status of the packages"

exit 0