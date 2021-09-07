KUSTOMIZE  = bin/kustomize build  --load-restrictor LoadRestrictionsNone --enable-alpha-plugins
JITSI_K8S_ENV ?= default

# -- Docker
# Get the current user ID to use for docker run and docker exec commands
DOCKER_UID           = $(shell id -u)
DOCKER_GID           = $(shell id -g)
DOCKER_USER          = $(DOCKER_UID):$(DOCKER_GID)
COMPOSE              = DOCKER_USER=$(DOCKER_USER) docker-compose


default: help

build: ## build the app container
	@$(COMPOSE) build app
.PHONY: build

bootstrap: ## Bootstrap the jitsi-k8s project
bootstrap: \
	env.d/kustomize \
	env.d/terraform

env.d/terraform:
	cp env.d/terraform.dist env.d/terraform

env.d/kustomize:
	cp env.d/kustomize.dist env.d/kustomize

k8s-apply-config: ## Build and deploy the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s/overlays/$(JITSI_K8S_ENV) | bin/kubectl apply -f -
.PHONY: k8s-apply-config

k8s-build-config: ## Build and display the Kubernetes configuration for jitsi
	@$(KUSTOMIZE) /data/k8s/overlays/$(JITSI_K8S_ENV)
.PHONY: k8s-build-config


help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help
