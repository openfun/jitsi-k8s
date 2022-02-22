# This provider is configured with the OS_* environment variables
# provider "openstack" {
# }

provider "scaleway" {
  access_key = lookup(var.scaleway_access_key, terraform.workspace, null)
  secret_key = lookup(var.scaleway_secret_key, terraform.workspace, null)
  project_id = lookup(var.scaleway_project_id, terraform.workspace, null)
}

provider "local" {

}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/.kubeconfig-${terraform.workspace}"
  }
}
