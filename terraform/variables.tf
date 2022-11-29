# Scaleway provider settings

variable "scaleway_access_key" {
  type = map(string)
  description = "The access key to use for the Scaleway provider"

  # This maps allows to use a different Scaleway accounts per workspace.
  # If not specified, the scaleway provider will fallback on the
  # SCW_ACCESS_KEY environment variable
  default = {
  }
}

variable "scaleway_secret_key" {
  type = map(string)
  description = "The secret key to use for the Scaleway provider"

  # This maps allows to use a different Scaleway accounts per workspace.
  # If not specified, the scaleway provider will fallback on the
  # SCW_SECRET_KEY environment variable
  default = {
  }
}

variable "scaleway_project_id" {
  type = map(string)
  description = "The id of the Scaleway project to use"

  # This maps allows to use a different Scaleway project per workspace.
  # If not specified, the scaleway provider will fallback on the
  # SCW_DEFAULT_PROJECT_ID environment variable
  default = {
  }
}

# Kubernetes cluster settings

variable "k8s_version" {
  type = map(string)
  description = "Kubernetes version to use"

  # Kubernetes version.
  # To list available versions, you can use the scaleway CLI :
  # scw k8s version list
  default = {
  }
}

variable "k8s_cni" {
  type = map(string)
  description = "Kubernetes container network interface to use"

  # Scaleway allows to specify the CNI to use in the kubernetes cluster.
  # You can list the available CNIs for your kubernetes version with scaleway CLI :
  # scw k8s version get 1.12.1
  default = {
  }
}

variable "k8s_auto_upgrade_enabled" {
  type = map(string)
  description = "Enable cluster auto upgrade"

  default = {
  }
}

variable "k8s_auto_upgrade_maintenance_window_start_hour" {
  type = map(number)
  description = "The start hour (UTC) of the 2-hour auto upgrade maintenance window (0 to 23)."

  default = {
  }
}

variable "k8s_auto_upgrade_maintenance_window_day" {
  type = map(string)
  description = "The day of the auto upgrade maintenance window (monday to sunday, or any)."

  default = {
  }
}

variable "k8s_autoscaler_scale_down_delay_after_add" {
  type = map(string)
  description = "How long after scale up that scale down evaluation resumes."

  # Given that Scaleway charges for at least an hour for every node that
  # is created, it should be set to a value slightly inferior to 1 hour.

  default = {
  }
}

variable "k8s_autoscaler_scale_down_unneeded_time" {
  type = map(string)
  description = "How long a node should be unneeded before it is eligible for scale down."

  default = {
  }
}

variable "k8s_autoscaler_max_graceful_termination_sec" {
  type = map(string)
  description = "Maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node."

  # It should be equal to the terminationGracePeriodSeconds variable on
  # the JVB deployment.

  default = {
  }
}

# Global Kubernetes nodepool settings

variable "k8s_nodepool_autohealing" {
  type = map(bool)
  description = "Enables the autohealing feature"

  # Auto-healing :
  # Health checks are run automatically to ensure your nodes are
  # functioning well. If for any reason your node does not respond for more
  # than 15 minutes, Kapsule will restart your node. If the status has not
  # improved, the node will be replaced.

  default = {
  }
}

variable "k8s_nodepool_container_runtime" {
  type = map(string)
  description = "The container runtime of the pool. "

  default = {
  }
}

# `default` nodepool settings

variable "k8s_default_nodepool_autoscale" {
  type = map(bool)
  description = "Enables the pool autoscaling feature"

  default = {
  }
}

variable "k8s_default_nodepool_flavor" {
  type = map(string)
  description = "Flavor name of the instances that will be created for the node pool"

  # You can get the list of available flavors here:
  # https://www.scaleway.com/en/pricing/

  default = {
    preprod = "DEV1-M"
  }
}

variable "k8s_default_nodepool_min_nodes" {
  type = map(number)
  description = "Minimum number of nodes allowed in the default node pool"

  default = {
  }
}

variable "k8s_default_nodepool_max_nodes" {
  type = map(number)
  description = "Maximum number of nodes allowed in the default node pool"

  default = {
  }
}

variable "k8s_default_nodepool_size" {
  type = map(number)
  description = "Desired pool size. This value will only be used at creation if autoscaling is enabled."

  default = {
  }
}


# `jibri` nodepool settings


variable "k8s_jibri_nodepool_autoscale" {
  type = map(bool)
  description = "Enables the pool autoscaling feature"

  default = {
  }
}

variable "k8s_jibri_nodepool_flavor" {
  type = map(string)
  description = "Flavor name of the instances that will be created in the jibri node pool"

  default = {
    preprod = "DEV1-L"
  }
}

variable "k8s_jibri_nodepool_min_nodes" {
  type = map(number)
  description = "Minimum number of nodes allowed in the jibri node pool"

  default = {
  }
}

variable "k8s_jibri_nodepool_max_nodes" {
  type = map(number)
  description = "Maximum number of nodes allowed in the jibri node pool"

  default = {
    preprod = 2
  }
}

variable "k8s_jibri_nodepool_size" {
  type = map(number)
  description = "Desired pool size. This value will only be used at creation if autoscaling is enabled."

  default = {
  }
}

# `jvb` nodepool settings


variable "k8s_jvb_nodepool_autoscale" {
  type = map(bool)
  description = "Enables the pool autoscaling feature"

  default = {
  }
}

variable "k8s_jvb_nodepool_flavor" {
  type = map(string)
  description = "Flavor name of the instances that will be created in the jvb node pool"

  default = {
    preprod = "DEV1-M"
  }
}

variable "k8s_jvb_nodepool_min_nodes" {
  type = map(number)
  description = "Minimum number of nodes allowed in the jvb node pool"

  default = {
  }
}

variable "k8s_jvb_nodepool_max_nodes" {
  type = map(number)
  description = "Maximum number of nodes allowed in the jvb node pool"

  default = {
    preprod = 2
  }
}

variable "k8s_jvb_nodepool_size" {
  type = map(number)
  description = "Desired pool size. This value will only be used at creation if autoscaling is enabled."

  default = {
  }
}


variable "k8s_ingress_nginx_version" {
  type = map(string)
  description = "ingress-nginx version to install"

  default = {
    preprod = "3.39.0"
  }
}

variable "k8s_grafana_ingress_enabled" {
  type = map(bool)
  description = "enable ingress for grafana UI"

  default = {
  }
}

variable "k8s_grafana_ingress_host" {
  type = map(string)
  description = "host to reach grafana admin"

  default = {
    preprod="grafana.preprod.exemple.com"
  }
}

variable "k8s_grafana_admin_passord" {
  type = map(string)
  description = "grafana admin password"

  default = {
    preprod="this is an invalid password"
  }
}