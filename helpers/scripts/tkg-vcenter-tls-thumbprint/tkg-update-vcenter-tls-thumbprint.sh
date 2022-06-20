#!/usr/bin/env bash

# Print usage of the script
function usage() {
  echo "Usage: $0 <TKG_MGMT_CLUSTER_NAME> <VCENTER_TLS_THUMBPRINT>"
  echo "For example: $0 tkg-mgmt-cls '26:3A:FF:3E:01:84:36:F5:BC:18:80:27:0E:14:59:AB:8E:1B:9E:53'"
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
VCENTER_TLS_THUMBPRINT=$2

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

# Loop through the workload clusters and updates the values.yaml of each CPI add-on secret
for workload_cluster in $(tanzu cluster list -o json | jq -r '.[].name')
do
    echo "Updating vCenter TLS thumbprint for workload cluster '$workload_cluster'"

    # Build secret name
    SECRET_NAME=$(echo "$workload_cluster-vsphere-cpi-addon")

    # Make sure the secret exists. Skip if it doesn't
    if [[ $(kubectl get secret "$SECRET_NAME" -n default --no-headers | wc -l) == "1" ]]; then
      # Get the secret, decode it, update the tlsThumbprint parameter, and patch the secret
      VALUES_B64=$(kubectl get secret "$SECRET_NAME" -n default -o jsonpath='{.data.values\.yaml}' | base64 -d | sed "0,/^\([[:space:]]*tlsThumbprint: *\).*/s//\1${VCENTER_TLS_THUMBPRINT}/;" - | base64 -w 0)
      kubectl patch secret "$SECRET_NAME" -n default --type='json' -p='[{"op" : "replace" ,"path" : "/data/values.yaml" ,"value" : '"$VALUES_B64"'}]'
    else
        echo "Secret '$SECRET_NAME' could not be found. Skipping..."
    fi

    # Patch the vSphereCluster resources
    kubectl patch vspherecluster "$workload_cluster" -n default --type='json' -p='[{"op" : "replace" ,"path" : "/spec/thumbprint" ,"value" : '"$VCENTER_TLS_THUMBPRINT"'}]'
done

# Update values.yaml of CPI add-on secret for the management cluster
SECRET_NAME=$(echo "$TKG_MGMT_CLUSTER_NAME-vsphere-cpi-addon")
VALUES_B64=$(kubectl get secret "$SECRET_NAME" -n tkg-system -o jsonpath='{.data.values\.yaml}' | base64 -d | sed "0,/^\([[:space:]]*tlsThumbprint: *\).*/s//\1${VCENTER_TLS_THUMBPRINT}/;" - | base64 -w 0)
kubectl patch secret "$SECRET_NAME" -n tkg-system --type='json' -p='[{"op" : "replace" ,"path" : "/data/values.yaml" ,"value" : '"$VALUES_B64"'}]'

# Patch the vSphereCluster management cluster resource
kubectl patch vspherecluster "$TKG_MGMT_CLUSTER_NAME" -n tkg-system --type='json' -p='[{"op" : "replace" ,"path" : "/spec/thumbprint" ,"value" : '"$VCENTER_TLS_THUMBPRINT"'}]'

echo ""
echo "Done!"
exit 0