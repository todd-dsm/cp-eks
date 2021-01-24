#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154
#  PURPOSE: Configures HashiCorp Vault for team use on AWS.
#           1) oAuth2 Logins via GitHub PATs
#              REF: https://bit.ly/3iJWJ59
#           2)
# -----------------------------------------------------------------------------
#  PREREQS: a) a cloud-provider service-account for Vault
#               the Member name should match the Name
#           b) That service-account needs these Roles, minimally:
#               * Project: Browser
#               * Service Accounts: Service Account Key Admin
#               * Service Accounts: Token Creator
#           c) Credentials must be created for the service-account
#               * it must be stored in a safe place.
#                   NOT: addons/secrets/vault/gcp-service-account.json
#                   * and .gitignored
#               * NOTE: the private_key_id ?
#           d)
#           e)
#           f)
#           g)
# -----------------------------------------------------------------------------
#  EXECUTE:
# -----------------------------------------------------------------------------
#     TODO: 1)
#           2)
#           3)
# -----------------------------------------------------------------------------
#   AUTHOR: Todd E Thomas
# -----------------------------------------------------------------------------
#  CREATED: 2020/06/12
# -----------------------------------------------------------------------------



###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# Data Files
source "$vaultStuff"
policyDir='addons/vault/policies'
# Private Vars - should not end up in logs
: "${ROOT_TOKEN?  Where is my Token, bro!}"
###---
### Login to Vault, quietly: TEST; should be unnecessary
###---
vault login token="$ROOT_TOKEN" > /dev/null 2>&1
###----------------------------------------------------------------------------

set -x
# ENV Stuff
# AWS IAM Service Account
#: "${TF_VAR_project?  Uhhh, I cant find the project}"
#iamMember="${svcAcctName}@${TF_VAR_project}.iam.gserviceaccount.com"
#iamMemberRef="$(gcloud iam service-accounts describe "$iamMember" \
#    --format='value(email)')"

# Kubernetes Support
kubesSAVaultAcct='vault-auth'

# Arrays
#authMethods=('github' 'aws' 'kubernetes')
authMethods=('github' 'kubernetes')

## GitHub Orgs
companyOrg='smpl-cloud'

vaultAdmins='sre'
declare -a githubOrgs=("$companyOrg")
declare -a sreEntities=('randolph.aarseth' 'todd.thomas' 'dan.stauffer')
#vaultAdminRole="${vaultAdmins}-role"

# Entities & Aliases
# Format: sreEntity,githubOrg,emailGitHub,useridGitHub
entAls=(
    "${sreEntities[1]},${githubOrgs[0]},todd.dsm@gmail.com,todd-dsm"
    "${sreEntities[1]},${githubOrgs[0]},taylor.smithgg@gmail.com,taylorsmithgg"
    "${sreEntities[0]},${githubOrgs[0]},bioblazepayne@gmail.com,Bioblaze"
    )


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '\n%s\n' "$theMessage"
}

# Configure Auth Method: GitHub
function confAuth-github() {
    for githubOrg in "${githubOrgs[@]}"; do
        pMsg "Enabling GitHub auth-method for: $githubOrg"
        #remote_support
        #vault write "auth/${githubOrg}/config" organization="$githubOrg"
        #vault write "auth/${githubOrg}/map/teams/${vaultAdmins}" value="$vaultAdmins"
        #self_support
        vault write  auth/github/config organization="$githubOrg"
        vault write "auth/github/map/teams/${vaultAdmins}" value="$vaultAdmins"
    done
}

# Configure Auth Method: AWS
# REF: https://www.vaultproject.io/docs/auth/aws
function confAuth-aws() {
    pMsg "Enabling Cloud auth-method for: GCP"
    vault write auth/gcp/config \
        credentials=@"addons/vault/${svcAcctName}-${TF_VAR_cluster_apps}.json"
    vault write "auth/gcp/role/${vaultAdminRole}" type='iam' \
        policies="$vaultAdmins" bound_service_accounts="$iamMemberRef"
}

# Create the Vault ServiceAccount in Kubernetes and define CRB
function createVaultSA() {
    pMsg "Creating Vault ServiceAccount in Kubernetes..."
    # Create Vault ServiceAccount
    kubectl create serviceaccount "$kubesSAVaultAcct"
    #sleep 1
    # Create Cluster Role Binding for Vault ServiceAccount
    cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: $kubesSAVaultAcct
  namespace: default
EOF
}

# Collect everything to populate Kubernetes Auth Method
function collectVaultSADeets() {
    pMsg "Collecting Vault ServiceAccount details from Kubernetes..."
    export kubeAPI="$(TERM=dumb kubectl cluster-info \ |
        grep "Kubernetes master" | awk '{print $NF}')"
    export defaultToken=$(kubectl get secrets | grep default | awk '{print $1}')
    export caCert=$(kubectl get secret "${defaultToken}" \
        -o jsonpath="{['data']['ca\\.crt']}" | base64 --decode)
    # Get SA Token to use for retrieval of the SA JWT
    export kubesSAToken="$(kubectl get serviceaccounts $kubesSAVaultAcct \
        -o jsonpath='{.secrets[].name}')"
    export kubesSAJWT="$(kubectl get secret "$kubesSAToken" \
        -o jsonpath='{.data.token}'  | base64 --decode)"
}

# Configure Auth Method: kubernetes
# REF: https://www.vaultproject.io/docs/auth/kubernetes
function confAuth-kubernetes() {
    pMsg "Enabling Kubernetes auth-method for Vault"
    vault write auth/kubernetes/config \
        token_reviewer_jwt="$kubesSAJWT" \
        kubernetes_host="${kubeAPI}:443" \
        kubernetes_ca_cert="$caCert"               # FIXME: shaky, hate this
}


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### FIRST CONFIGURATION ALWAYS: Enable Auditing
###---
pMsg "Enabling Vault Auditing..."
vault audit enable file file_path=stdout


###----------------------------------------------------------------------------
### Prep Kubernetes Auth Method
###----------------------------------------------------------------------------
# create the vault TokenReviewer service account in kubernetes
createVaultSA

### let's go shopping
collectVaultSADeets


###----------------------------------------------------------------------------
### Create an Admin Policy
###----------------------------------------------------------------------------
pMsg "Configuring Vault Policy for ${vaultAdmins^^}s..."
vault policy write "$vaultAdmins" "$policyDir/${vaultAdmins}-policy.hcl"

###---
### Auth Methods
###---
pMsg "Enabling Auth Methods..."
for method in "${authMethods[@]}"; do
    pMsg "  $method"
    case $method in
        github)
            #remote_support
            #for myOrg in "${githubOrgs[@]}"; do
            #    vault auth enable -path="$myOrg" "$method"
            #done
            #self_support
            vault auth enable "$method"
            "confAuth-${method}"
            ;;
        aws)
            vault auth enable "$method"
            "confAuth-${method}"
            ;;
        kubernetes)
            vault auth enable "$method"
            "confAuth-${method}"
            ;;
    esac
done


###----------------------------------------------------------------------------
### Create Entities in Vault and Alias them to Cloud and GitHub
###----------------------------------------------------------------------------
set -x
pMsg "Add all Entities and Aliases..."
for adminDeets in "${entAls[@]}"; do
    while IFS=',' read -r sreEntity githubOrg emailGitHub useridGitHub; do
        printf '%s\n' "$sreEntity - $githubOrg - $emailGitHub - $useridGitHub"
        vault write identity/entity name="$sreEntity" policies="$vaultAdmins" \
            metadata=organization="$githubOrg" \
            metadata=team="Site Reliability Engineering"
        #----------------------------------------------------------------------
        # Create Alias: AWS
        #----------------------------------------------------------------------
        #gcpAccessor=$(vault auth list -format=json | jq -r '.["gcp/"].accessor')
        # for each user
        #entityID=$(vault read "identity/entity/name/${sreEntity}" \
        #    -format=json | jq -r '.data.id')

        #pMsg "Creating GCP alias for $sreEntity"
        #vault write identity/entity-alias name="$emailGitHub" \
        #    canonical_id="$entityID" mount_accessor="$gcpAccessor"
        #
        #----------------------------------------------------------------------
        # Create Alias: GitHub
        #----------------------------------------------------------------------
        # jq will get compile errors if the quotes aren't as below: !@#$
        githubAccessor=$(vault auth list -format=json | \
            #self_support
            jq -r '.["github/"].accessor')
            #remote_support
            #jq -r '.["smpl-cloud/"].accessor')
        # for each user
        entityID=$(vault read "identity/entity/name/${sreEntity}" \
            -format=json | jq -r '.data.id')

        pMsg "Creating GitHub alias for $sreEntity"
        vault write identity/entity-alias name="$useridGitHub" \
            canonical_id="$entityID" mount_accessor="$githubAccessor"
    done <<< "$adminDeets"
done


# FIXME
#vault login -method=gcp role="sre" \
#    jwt_exp="15m" credentials=@addons/vault/vault-iam-voilamed-stage.json
#vault login -method=github -ca-cert="secrets/certs/ca.pem" token="token"


###----------------------------------------------------------------------------
### Secrets Engine; database: MySQL/MariaDB (managed)
### URL: https://www.vaultproject.io/docs/secrets/databases/mysql-maria.html
###----------------------------------------------------------------------------
### Enable the database secrets engine
###---
pMsg """
    *************************************************************
                    Enabling Secrets Engine: Database
    *************************************************************
"""
vault secrets enable database


###----------------------------------------------------------------------------
### Configure Kubernetes Auth Method
###----------------------------------------------------------------------------
# TEST: Create a named role
vault write auth/kubernetes/role/app \
    bound_service_account_names="$kubesSAVaultAcct" \
    bound_service_account_namespaces=default \
    policies=default \
    ttl=1h


###---
### REQ
###---


###---
### fin~
###---
exit 0
