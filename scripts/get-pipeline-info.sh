#!/usr/bin/env bash


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}

function pRpt() {
    theMessage="$1"
    printf '\n%s\n' "$theMessage"
}
###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

# Grab api url from cluster-info
api_url=$(kubectl cluster-info | grep "Kubernetes master" | awk '{print $NF}')

# Grab cert using default token
default_token=$(kubectl get secrets | grep default | awk '{print $1}')
ca_cert=$(kubectl get secret "$default_token" -o jsonpath="{['data']['ca\.crt']}" | base64 --decode)

# Create gitlab-admin service account
kubectl create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
    name: gitlab-admin
    namespace: kube-system
EOF

kubectl create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
    name: gitlab-admin
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
subjects:
- kind: ServiceAccount
  name: gitlab-admin
  namespace: kube-system
EOF

service_token=$(kubectl -n kube-system describe secret "$(kubectl \
    -n kube-system get secret | grep gitlab-admin | awk '{print $1}')" | \
    grep token: | awk '{print $NF}')

pMsg "==========================="
pMsg """
API URL:
$api_url
"""
pMsg """
CA Certificate:
$ca_cert"""
pMsg """
Token:
$service_token
"""
