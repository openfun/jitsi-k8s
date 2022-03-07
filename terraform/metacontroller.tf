
# Install metacontroller with Helm, to be able to use service-per-pod

resource "helm_release" "metacontroller" {
  
  name = "metacontroller"
  chart = "oci://ghcr.io/metacontroller/metacontroller-helm"
  version = "v2.2.5"
  namespace = "metacontroller"
  create_namespace = "true"

  depends_on = [
    scaleway_k8s_pool.default,
    local_file.kubeconfig
  ]
}
