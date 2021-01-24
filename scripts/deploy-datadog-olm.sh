#!/usr/bin/env bash
#  PURPOSE: Datadog automated deployment with the Operator Lifecycle Manager:
#           https://github.com/operator-framework/operator-lifecycle-manager
# -----------------------------------------------------------------------------
#  PREREQS: a)
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
#: "${1?  Wheres my first agument, bro!}"

olmVersion='0.15.1'
olmRelease="releases/download/${olmVersion}/install.sh"
olmScript="https://github.com/operator-framework/operator-lifecycle-manager/${olmRelease}"

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
### Install Operator Lifecycle Manager (OLM)
###---
pMsg "Installing the Operator Lifecycle Manager..."
curl -sL "$olmScript" | bash -s "$olmVersion"


###---
### Install the Datadog operator (in the "operators" namespace)
###---
pMsg "Installing the Datadog Operator..."
kubectl create -f https://operatorhub.io/install/datadog-operator.yaml


###---
### get deployment status
###---
kubectl -n operators get csv


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
### REQ
###---


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
### REQ
###---


###---
### fin~
###---
exit 0
