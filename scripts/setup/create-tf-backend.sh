#!/usr/bin/env bash
# shellcheck disable=SC2154
# -----------------------------------------------------------------------------
# PURPOSE:  1-time setup for the admin-project and terraform user account.
#           Some controls are necessary at the Organization and project level.
# -----------------------------------------------------------------------------
# PREREQS:  source-in all your environment variables from build.env
# -----------------------------------------------------------------------------
#    EXEC:  scripts/setup/create-tf-backend.sh
# -----------------------------------------------------------------------------
: "${stateLockDynamoDB?  I dont have my vars, bro!}"
#set -x

###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
backendDef='backend.hcl'


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}

function removeTFdir() {
    if [[ -d .terraform ]]; then
        echo "Removing the previous state file..."
        rm -rf .terraform &> /dev/null
    fi

}

### Create the Terraform bucket definition for the backend
function createBackend() {
    pMsg "  Creating Terraform backend definition..."
    cat > "$backendDef" <<EOF
/*
  -----------------------------------------------------------------------------
                           CENTRALIZED HOME FOR STATE
                           inerpolations NOT allowed
  -----------------------------------------------------------------------------
*/
dynamodb_table  = "$stateLockDynamoDB"
bucket          = "$TF_VAR_stateBucket"
key             = "${myComponent}/${TF_VAR_envBuild}"
region          = "$TF_VAR_region"
encrypt         = true

EOF
}

###----------------------------------------------------------------------------
### MAIN
###----------------------------------------------------------------------------
### Validate Backend File
### File does NOT exist
if [[ ! -f ./${backendDef} ]]; then
    createBackend
else
    # File exists
    # Validate Contents of Backend File
    currentTable="$(grep dynamodb_table $backendDef | awk '{print $3}' | tr -d '"')"
    if [[ "$currentTable" != "$stateLockDynamoDB" ]]; then
        removeTFdir
        createBackend
    fi
fi

###---
### fin~
###---
exit 0

