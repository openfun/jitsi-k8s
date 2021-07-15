
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

# In this cluster, we create 2 nodepools :
#
# - The `default` nodepool, on which we'll deploy all pods that do not require
#   autoscaling feature (e.g. the prometheus stack and basic jitsi components
#   like prosody and jitsi-meet webserver). It is desirable to isolate them from
#   nodepools with autoscaling enabled, as they can prevent the Cluster Autoscaler
#   from removing a node if they run on them.
#
# - The `jibri` nodepool, dedicated to jibri instances, with autoscaling enabled.
#
# In the future, we'll propably add a nodepool dedicated to videobridges.
#
# This separation allows to choose instance types adapted to the needs of each
# component (e.g. : Jibri consumes a lot of CPU/RAM, Videobridges consume a lot of
# bandwdith).


resource "scaleway_k8s_pool" "default" {
   autohealing         = lookup(var.k8s_nodepool_autohealing, terraform.workspace, true)
   autoscaling         = false
   cluster_id          = scaleway_k8s_cluster.kube_cluster.id
   container_runtime   = lookup(var.k8s_nodepool_container_runtime, terraform.workspace, "containerd")
   name                = "default"
   node_type           = lookup(var.k8s_default_nodepool_flavor, terraform.workspace, "GP1-XS")
   size                = lookup(var.k8s_default_nodepool_size, terraform.workspace, 1)
   wait_for_pool_ready = true
}


resource "scaleway_k8s_pool" "jibri" {
   autohealing         = lookup(var.k8s_nodepool_autohealing, terraform.workspace, true)
   autoscaling         = lookup(var.k8s_jibri_nodepool_autoscale, terraform.workspace, true)
   cluster_id          = scaleway_k8s_cluster.kube_cluster.id
   container_runtime   = lookup(var.k8s_nodepool_container_runtime, terraform.workspace, "containerd")
   max_size            = lookup(var.k8s_jibri_nodepool_max_nodes, terraform.workspace, 5)
   min_size            = lookup(var.k8s_jibri_nodepool_min_nodes, terraform.workspace, 1)
   name                = "jibri"
   node_type           = lookup(var.k8s_jibri_nodepool_flavor, terraform.workspace, "GP1-S")
   size                = lookup(var.k8s_jibri_nodepool_size, terraform.workspace, 1)
   wait_for_pool_ready = false

   # We wait for default pool to be ready before creating the jibri pool,
   # otherwise some kube-system pods created by scaleway might be scheduled
   # on the jibri pool at cluster initialization
   depends_on = [ scaleway_k8s_pool.default ]
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
