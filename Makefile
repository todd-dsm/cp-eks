#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Grab some ENV stuff
KUBECONFIG		?= $(shell $(KUBECONFIG))
TF_VAR_cluster_apps	?= $(shell $(TF_VAR_cluster_apps))
TF_VAR_stateBucket	?= $(shell $(TF_VAR_stateBucket))
planFile		?= $(shell $(planFile))

# Start Terraforming
#prep:	## Prepare for the build
#	@setup/create-project-bucket.sh

all:	tf-init plan apply creds
#all:	tf-init plan apply creds xdns scale observe  ## All-in-one 

tf-init: ## Initialze the build
	date
	terraform init -get=true -backend=true -reconfigure \
		-backend-config="backend.hcl"

plan:	## Initialze and Plan the build with output log
	terraform plan -no-color \
		-out=$(planFile) 2>&1 | \
		tee /tmp/tf-$(TF_VAR_cluster_apps)-plan.out

apply:	## Build Terraform project with output log
	terraform apply --auto-approve -no-color \
		-input=false "$(planFile)" 2>&1 | \
		tee /tmp/tf-$(TF_VAR_cluster_apps)-apply.out
	date

creds:	## Update the local KUBECONFIG with the new cluster details
	@scripts/get-creds.sh 2>&1 | tee '/tmp/get-creds.out' 

observe: ## Deploy Datadog
	@scripts/deploy-datadog.sh 2>&1 | tee '/tmp/datadog-install.out' 

vault:	## Deploy Official HashiCorp Vault via Helm chart
	@scripts/vault-inst-official.sh 2>&1 | tee '/tmp/vault-install.out'
	#@scripts/vault-conf.sh 2>&1 | tee /tmp/vault-conf.out

xdns:	## installs metrics server
	kubectl apply -f addons/xdns/ 
	@scripts/conf-cluster-autoscaler.sh

scale:	## installs metrics server
	helm install stable/metrics-server --name metrics-server \
		--version 2.0.4 --namespace metrics 
	scripts/wait-metrics-server-ready.sh

	date
	
pipe_info: ## dumps out information required for GitLabs k8s cluster setup	   
	scripts/get-pipeline-info.sh						   

# ------------------------ 'make all' ends here ------------------------------#

graph:	## Create a visual graph pre-build 
	scripts/graphit.sh

ingress: ## install ingress
	kubectl apply -f addons/nginx-ingress/ingress.yml

scaletest: ## Tests HPA scaling
	kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80 -l app=php-apache
	kubectl autoscale deployment php-apache --cpu-percent=15 --min=1 --max=10
	screen -dmS hpa bash -c 'kubectl get hpa -w > /tmp/hpa.out'
	screen -dmS pods bash -c 'kubectl get pods -w > /tmp/pods.out'
	#kubectl run -it load-generator --image=busybox --restart=Never --rm -- /bin/sh -c "while true; do wget -q -O - http://php-apache; done"
	#kubectl exec -it load-generator -- /bin/sh -c "while true; do wget -q -O - http://php-apache; done"

scaleresults: ## Prints the scale results
	cat /tmp/hpa.out /tmp/pods.out
	
scaleclean: ## Cleans up the junk created from the scale test
	rm -f /tmp/hpa.out /tmp/pods.out
	screen -X -S hpa quit | true
	screen -X -S pods quit | true
	kubectl delete hpa php-apache | true
	kubectl delete svc php-apache | true
	kubectl delete pod load-generator | true
	kubectl delete deployment php-apache | true
	#scripts/load-un.sh

exfil:	## Destroy current vault deployment
	@scripts/vault-exfil.sh 2>&1 | tee '/tmp/vault-uninstall.out'

exfil-full:  ## Destroy current vault deployment - completely
	@scripts/vault-exfil.sh --purge 2>&1 | tee '/tmp/vault-uninstall.out' 

clean:	## Clean WARNING Message
	@echo ""
	@echo "Destroy $(TF_VAR_cluster_apps)?"
	@echo ""
	@echo "***** STOP, THINK ABOUT THIS *****"
	@echo "  First, remove the GitLab Integrations"
	@echo "IF YOU'RE CERTAIN, THEN 'make clean-all'"
	@echo ""
	@exit

clean-all:	## Destroy Terraformed resources and all generated files with output log
	date
	terraform destroy --force -no-color 2>&1 | \
		tee /tmp/tf-$(TF_VAR_cluster_apps)-destroy.out
	rm -f "$(planFile)"
	rm -rf .terraform
	rm -rf $(KUBECONFIG)
	#aws logs delete-log-group --log-group-name "/aws/eks/ptest-stage/cluster"
	#dump
	date

dump:	## clear-off kubeconfig cruft
	kubectl config delete-context $(TF_VAR_cluster_apps)

creds-update:	dump creds ## Update kubeconfig file with current cluster

#-----------------------------------------------------------------------------#
#------------------------   MANAGERIAL OVERHEAD   ----------------------------#
#-----------------------------------------------------------------------------#
print-%  : ## Print any variable from the Makefile (e.g. make print-VARIABLE);
	@echo $* = $($*)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

