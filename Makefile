KUSTOMIZE  = bin/kustomize build  --load_restrictor LoadRestrictionsNone

default: help

bootstrap: ## Bootstrap the jitsi-k8s project
bootstrap: \
	env.d/jitsi \
	env.d/jitsi-secrets \
	env.d/terraform
.PHONY: bootstrap

env.d/terraform:
	cp env.d/terraform.dist env.d/terraform

env.d/jitsi:
	cp env.d/jitsi.dist env.d/jitsi
	@echo "Please configure the env.d/jitsi environment file (replace YOUR_DOMAIN with your jitsi domain name)."

env.d/jitsi-secrets:
	cp env.d/jitsi-secrets.dist env.d/jitsi-secrets
	@echo "Please configure the env.d/jitsi-secrets environment file."


k8s-apply-config: ## Build and deploy the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s | bin/kubectl apply -f -
.PHONY: k8s-apply-config

k8s-build-config: ## Build and display the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s
.PHONY: k8s-build-config


help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
