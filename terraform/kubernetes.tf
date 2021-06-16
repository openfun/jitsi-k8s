
resource "ovh_cloud_project_kube" "kube_cluster" {
   name         = "jitsi-${terraform.workspace}"
   region       = lookup(var.k8s_cluster_region, terraform.workspace, "GRA7")
   service_name = lookup(var.ovh_project_id, terraform.workspace, null)

   lifecycle {
      ignore_changes = [ version ]
   }
}

resource "ovh_cloud_project_kube_nodepool" "kube_nodepool" {
   autoscale     = lookup(var.k8s_nodepool_autoscale, terraform.workspace, false)
   flavor_name   = lookup(var.k8s_nodepool_flavor, terraform.workspace, "b2-15")
   kube_id       = ovh_cloud_project_kube.kube_cluster.id
   max_nodes     = lookup(var.k8s_nodepool_max_nodes, terraform.workspace, 1)
   min_nodes     = lookup(var.k8s_nodepool_min_nodes, terraform.workspace, 1)
   name          = "jitsipool-${terraform.workspace}"
   service_name  = lookup(var.ovh_project_id, terraform.workspace, null)

   lifecycle {
      ignore_changes = [ desired_nodes ]
   }
}

output "kubeconfig" {
   value = ovh_cloud_project_kube.kube_cluster.kubeconfig
   sensitive = true
   description = "The kube config file to use to connect to the cluster"
}

output "k8s_nodes_url" {
   value = ovh_cloud_project_kube.kube_cluster.nodes_url
   description = "Cluster nodes URL (DNS record that return all nodes addresses)"
}

resource "local_file" "kubeconfig" {
   sensitive_content = ovh_cloud_project_kube.kube_cluster.kubeconfig
   filename = "${path.module}/.kubeconfig-${terraform.workspace}"
   file_permission = "0600"
}
