
terraform {
  required_providers {
    # openstack = {
    #   source = "terraform-provider-openstack/openstack"
    #   version = "1.42.0"
    # }

    helm = {
      source = "hashicorp/helm"
      version = "2.1.2"
    }

    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }

    scaleway = {
      source = "scaleway/scaleway"
      version = "2.2.0"
    }

  }

  backend "s3" {
    bucket = "jitsi-k8s-terraform"
    key = "mystate.tfstate"
    region = "fr-par"
    endpoint = "https://s3.fr-par.scw.cloud"
    skip_region_validation = true
    skip_credentials_validation = true
  }

  required_version = ">= 0.15"
}
