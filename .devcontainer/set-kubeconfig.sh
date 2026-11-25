#!/bin/bash
# Stores the kubeconfig of the workshop k3d cluster (which runs on your own
# machine, next to this container) and points it at host.containers.internal.
# Usage: paste the output of `k3d kubeconfig get workshop`, then press Ctrl+D.
set -euo pipefail

target="${KUBECONFIG:-$HOME/.kube/config}"

if [[ -t 0 ]]; then
    echo "Paste the output of 'k3d kubeconfig get workshop', then press Ctrl+D:"
fi
config="$(cat)"
if ! grep -q 'server: https://' <<<"$config"; then
    echo "That does not look like a kubeconfig (no 'server: https://' line)." >&2
    exit 1
fi

mkdir -p "$(dirname "$target")"
sed -E 's#server: https://(0\.0\.0\.0|127\.0\.0\.1|localhost|host\.docker\.internal):#server: https://host.containers.internal:#' \
    <<<"$config" > "${target}.tmp"
chmod 600 "${target}.tmp"
mv "${target}.tmp" "$target"

echo "Saved to $target. Checking the cluster..."
kubectl get nodes
