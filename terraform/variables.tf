
# OVH provider settings

variable "ovh_endpoint" {
  type = string
  default = "ovh-eu"
  description = "The OVH API endpoint to use"
}

variable "ovh_project_id" {
  type = map(string)
  description = "The id of the public cloud project to use"

  # This maps allows to use a different OVH cloud project per workspace.
  # If not specified, the ovh provider will fallback on the
  # OVH_CLOUD_PROJECT_SERVICE environment variable
  default = {
  }
}

# OVH managed Kubernetes cluster settings

variable "k8s_cluster_region" {
  type = map(string)
  description = "The OVH region in which the k8s cluster will be created."

  default = {
    production = "GRA7"
  }
}


# Kubernetes nodepool settings

variable "k8s_nodepool_autoscale" {
  type = map(bool)
  description = "Enables the pool autoscaling feature"

  default = {
    production = true
  }
}

variable "k8s_nodepool_flavor" {
  type = map(string)
  description = "Flavor name of the instances that will be created for the node pool"

  default = {
    production = "b2-15"
  }
}

variable "k8s_nodepool_min_nodes" {
  type = map(number)
  description = "Minimum number of nodes allowed in the node pool"

  default = {
    production = 1
  }
}

variable "k8s_nodepool_max_nodes" {
  type = map(number)
  description = "Maximum number of nodes allowed in the pool"

  default = {
    preprod = 2
    production = 5
  }
}
