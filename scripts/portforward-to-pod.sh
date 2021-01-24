#!/usr/bin/env bash
# shellcheck disable=SC2154
#  PURPOSE: port-forward out to a running container on $myPort
# -----------------------------------------------------------------------------
#  PREREQS: a)
#           b)
#           c)
# -----------------------------------------------------------------------------
#  EXECUTE:     scripts/portforward-to-pod.sh myApp   myPort
#               scripts/portforward-to-pod.sh vault-0 8200
# -----------------------------------------------------------------------------
#     TODO: 1) add options for arguments
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2019/04/06
# -----------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
#"${1?  Wheres my first agument, bro!}"
# ENV Stuff
myApp="$1"
myPort="$2"

# Data Stuff
# when using vault
#export VAULT_ADDR="https://127.0.0.1:${myPort}"
#export VAULT_CACERT="$certDir/ca.pem"


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
### print messages
###---
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}


###---
### do the work
###---
function portForward() {
    targetPod="$1"
    screen -dmS "$myApp" /bin/bash -c \
        "kubectl port-forward $targetPod ${myPort}:${myPort}"
    # make the announcement
    pMsg """

    All clear! Forwarding port $myPort to the $myApp container.

    """
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### Announce
###---
pMsg """


    *************************************************************
              Port-Forwarding out to the ${myApp^} Container
    *************************************************************

"""


###---
### get pod name
###---
#podName="$(kubectl get pod -l app="$myApp" -o jsonpath='{.items[0].metadata.name}')"
podName="$myApp"


###---
### see if we already have ports forwarded out
###---
lsofResponse="$(sudo lsof -i ":${myPort}")"
if [[ -z "$lsofResponse" ]]; then
    # create a path to the remote service
    portForward "$podName"
else
    pMsg """
    Looks like we're good to go:
    $lsofResponse
    """
fi


###---
### List conditions
###---
screen -list
sleep 1
sudo lsof -i ":${myPort}"


###---
### wait for a beat
###---
sleep 5


###---
### fin~
###---
exit 0
