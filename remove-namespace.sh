#!/usr/bin/env bash

# remove-namespace-finalizers.sh
#
# Usage:
#   ./remove-namespace-finalizers.sh <namespace>
#
# Example:
#   ./remove-namespace-finalizers.sh flux-system
#
# This script:
#   1. Removes all finalizers from all namespaced resources in <namespace>.
#   2. Removes finalizers from the namespace object itself.
#   3. Lets Kubernetes proceed with deletion of the namespace.

NAMESPACE="$1"

if [ -z "$NAMESPACE" ]; then
  echo "ERROR: No namespace provided."
  echo "Usage: $0 <namespace>"
  exit 1
fi

echo "==> Forcibly removing finalizers in namespace: ${NAMESPACE}"

# 1. Remove finalizers from all namespaced resources in this namespace
echo "==> Removing finalizers from all resources in ${NAMESPACE}..."
RESOURCES=$(kubectl api-resources --namespaced=true --verbs=list -o name)
for RESOURCE in $RESOURCES; do
  # Fetch items for this resource type in the target namespace
  ITEMS=$(kubectl get "${RESOURCE}" -n "${NAMESPACE}" --no-headers 2>/dev/null | awk '{print $1}')
  # If no items, skip
  [ -z "$ITEMS" ] && continue

  for ITEM in $ITEMS; do
    echo "    -> Patching ${RESOURCE}/${ITEM}"
    kubectl patch "${RESOURCE}" "${ITEM}" \
      -n "${NAMESPACE}" \
      --type=merge \
      -p '{"metadata":{"finalizers":[]}}' \
      >/dev/null 2>&1
  done
done

# 2. Remove finalizers from the namespace itself
echo "==> Removing finalizers from the namespace object..."
kubectl patch namespace "${NAMESPACE}" --type=merge -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1

echo "==> Done! Namespace '${NAMESPACE}' should now finalize and delete."

