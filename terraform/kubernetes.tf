
resource "ovh_cloud_project_kube" "kube_cluster" {
   name         = var.k8s_cluster_name
   region       = var.k8s_cluster_region

   lifecycle {
      ignore_changes = [ version ]
   }
}

resource "ovh_cloud_project_kube_nodepool" "kube_nodepool" {
   kube_id       = ovh_cloud_project_kube.kube_cluster.id
   name          = "jitsipool"
   flavor_name   = var.k8s_nodepool_flavor
   max_nodes     = var.k8s_nodepool_max_nodes
   min_nodes     = var.k8s_nodepool_min_nodes
   autoscale     = var.k8s_nodepool_autoscale

   lifecycle {
      ignore_changes = [ desired_nodes ]
   }
}

output "kubeconfig" {
   value = ovh_cloud_project_kube.kube_cluster.kubeconfig
   sensitive = true
   description = "The kube config file to use to connect to the cluster"
}

resource "local_file" "kubeconfig" {
   sensitive_content = ovh_cloud_project_kube.kube_cluster.kubeconfig
   filename = "${path.module}/.kubeconfig"
   file_permission = "0600"
}
