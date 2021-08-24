
# Install cert-manager with Helm, to be able to create TLS certificates
# with Let's encrypt

resource "helm_release" "cert-manager" {

  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"

  set {
    name = "installCRDs"
    value = true
  }

  set {
    name = "nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  set {
    name = "webhook.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  set {
    name = "cainjector.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  depends_on = [
    scaleway_k8s_pool.default,
    local_file.kubeconfig,
    helm_release.kube-prometheus-stack
  ]

}

