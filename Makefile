KUSTOMIZE  = bin/kustomize build  --load_restrictor LoadRestrictionsNone

JITSI_K8S_ENV ?= default

default: help

bootstrap: ## Bootstrap the jitsi-k8s project
bootstrap: \
	env.d/terraform

env.d/terraform:
	cp env.d/terraform.dist env.d/terraform

k8s-apply-config: ## Build and deploy the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s/overlays/$(JITSI_K8S_ENV) | bin/kubectl apply -f -
.PHONY: k8s-apply-config

k8s-build-config: ## Build and display the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s/overlays/$(JITSI_K8S_ENV)
.PHONY: k8s-build-config


help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
