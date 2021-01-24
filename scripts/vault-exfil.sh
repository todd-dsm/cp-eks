#!/usr/bin/env bash
# shellcheck disable=SC2154
# FIXME: change: priv -> private
# work backwards
set -x

# Dump Vault
helm uninstall vault
kubectl delete sa vault-auth
kubectl delete clusterrolebindings role-tokenreview-binding

if [[ $1 == "--purge" ]]; then
    kubectl delete pvc -l app.kubernetes.io/instance=vault
fi

rm -f "$vaultStuff"
#kubectl delete configmap vault
#kubectl delete secret vault
#kubectl delete serviceaccount vault-auth

# Dump the portforwarding
sudo lsof -i :8200 | awk 'NR > 1 {print $2}' | xargs kill -9

