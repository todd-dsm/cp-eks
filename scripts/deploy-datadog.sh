#!/usr/bin/env bash
#  PURPOSE: Datadog automated deployment with Helm; officially supported.
# -----------------------------------------------------------------------------
#  PREREQS: a) configure helm repos
#               * helm repo add datadog https://helm.datadoghq.com
#               * helm repo add stable https://kubernetes-charts.storage.googleapis.com/
#               * helm repo update
#           b)
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE:
# -----------------------------------------------------------------------------
#     TODO: 1)
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2020/08/24
# -----------------------------------------------------------------------------
set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# ENV Stuff
: "${DATADOG_API_KEY?  Wheres my DATADOG_API_KEY, bro!}"

# Data


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Install Datadog via Helm
###---
pMsg "Installing Datadog via Helm..."
helm install datadog -f addons/observe/values.yaml \
    --set datadog.apiKey="$DATADOG_API_KEY" datadog/datadog


###---
### Wait for it...
###---
kubectl wait --for=condition=ready pod -l app=datadog --timeout=2m


###---
### REQ
###---


###---
### REQ
###---


###---
### REQ
###---


###---
### fin~
###---
exit 0
