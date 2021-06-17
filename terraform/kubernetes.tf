
resource "scaleway_k8s_cluster" "kube_cluster" {
   name    = "jitsi-${terraform.workspace}"
   version = lookup(var.k8s_version, terraform.workspace, "1.21")
   cni     = lookup(var.k8s_cni, terraform.workspace, "cilium")

   auto_upgrade {
      enable = lookup(var.k8s_auto_upgrade_enabled, terraform.workspace, true)
      maintenance_window_start_hour = lookup(var.k8s_auto_upgrade_maintenance_window_start_hour, terraform.workspace, 3)
      maintenance_window_day = lookup(var.k8s_auto_upgrade_maintenance_window_day, terraform.workspace, "any")
   }

}

resource "scaleway_k8s_pool" "kube_nodepool" {
   autohealing         = lookup(var.k8s_nodepool_autohealing, terraform.workspace, true)
   autoscaling         = lookup(var.k8s_nodepool_autoscale, terraform.workspace, false)
   cluster_id          = scaleway_k8s_cluster.kube_cluster.id
   container_runtime   = lookup(var.k8s_nodepool_container_runtime, terraform.workspace, "containerd")
   max_size            = lookup(var.k8s_nodepool_max_nodes, terraform.workspace, 1)
   min_size            = lookup(var.k8s_nodepool_min_nodes, terraform.workspace, 1)
   name                = "jitsi-${terraform.workspace}"
   node_type           = lookup(var.k8s_nodepool_flavor, terraform.workspace, "GP1-XS")
   size                = lookup(var.k8s_nodepool_size, terraform.workspace, 1)
   wait_for_pool_ready = true
}

output "kubeconfig" {
   value = scaleway_k8s_cluster.kube_cluster.kubeconfig[0].config_file
   sensitive = true
   description = "The kube config file to use to connect to the cluster"
}

output "k8s_nodes_url" {
   value = scaleway_k8s_cluster.kube_cluster.wildcard_dns
   description = "Cluster nodes URL (DNS record that return all nodes addresses)"
}

resource "local_file" "kubeconfig" {
   sensitive_content = scaleway_k8s_cluster.kube_cluster.kubeconfig[0].config_file
   filename = "${path.module}/.kubeconfig-${terraform.workspace}"
   file_permission = "0600"
}
