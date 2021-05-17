
resource "ovh_cloud_project_kube" "kube_cluster" {
   name         = var.k8s_cluster_name
   region       = var.k8s_cluster_region
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
}
