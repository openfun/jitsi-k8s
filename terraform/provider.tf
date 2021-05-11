# This provider is configured with the OS_* environment variables
provider "openstack" {
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
}
