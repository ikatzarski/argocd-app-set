SHELL := /bin/bash

CLUSTER_NAME = argo-cd-app-set

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "%-25s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install-k8s-with-kind: ## Install K8s with Kind (requires 'CLUSTER_NAME' to be set and Kind to be installed)
	kind create cluster --name $(CLUSTER_NAME)

install-argocd: ## Create argocd namespace and install Argo CD
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

install-app-set: ## Install the example Argo CD Application Set (requires 'ENVIRONMENT' to be set)
	test -n "$(ENVIRONMENT)"  # Provide $$ENVIRONMENT
	helm upgrade --install nginx-app-set-${ENVIRONMENT} app-set \
	--set env="${ENVIRONMENT}" \
	--set argoRepo="https://github.com/ikatzarski/argocd-app-set.git" \
	--set configRepo="https://github.com/ikatzarski/argocd-app-set.git" \
	--set configRevision="HEAD" \
	--set configFile="config/${ENVIRONMENT}.yaml" \
	--set appsRepo="https://github.com/ikatzarski/argocd-app-set.git" \
	--set appsRevision="HEAD" \
	--set appsChart="apps" \
	--namespace argocd \
	--create-namespace \
	--atomic \
	--wait

port-forward-argocd: ## Port-forward to the Argo CD service, open http://localhost:8080
	@echo "User: admin"
	@echo "Password: $(shell kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

delete: ## Delete the K8s cluster
	kind delete cluster --name $(CLUSTER_NAME)
