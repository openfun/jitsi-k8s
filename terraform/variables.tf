
# OVH provider settings

variable "ovh_endpoint" {
  type = string
  default = "ovh-eu"
  description = "The OVH API endpoint to use"
}

# OVH managed Kubernetes cluster settings

variable "k8s_cluster_name" {
  type = string
  default = "jitsi"
  description = "The name of the k8s cluster"
}

variable "k8s_cluster_region" {
  type = string
  default = "GRA7"
  description = "The OVH region in which the k8s cluster will be created."
}


# Kubernetes nodepool settings

variable "k8s_nodepool_autoscale" {
  type = bool
  default = false
  description = "Enables the pool autoscaling feature"
}

variable "k8s_nodepool_flavor" {
  type = string
  description = "Flavor name of the instances that will be created for the node pool"
  default = "b2-7"
}

variable "k8s_nodepool_min_nodes" {
  type = number
  default = 1
  description = "Minimum number of nodes allowed in the node pool"
}

variable "k8s_nodepool_max_nodes" {
  type = number
  default = 1
  description = "Maximum number of nodes allowed in the pool"
}
