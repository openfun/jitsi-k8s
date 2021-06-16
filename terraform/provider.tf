# This provider is configured with the OS_* environment variables
provider "openstack" {
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
}

provider "local" {

}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/.kubeconfig-${terraform.workspace}"
  }
}
