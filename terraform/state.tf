
terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.42.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.1.2"
    }

    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }

    ovh = {
      source = "ovh/ovh"
      version = "0.13.0"
    }

  }

  backend "swift" {
    container = "jitsi-k8s-terraform"
  }

  required_version = ">= 0.15"
}
