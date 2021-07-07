
# Install the helm kube-prometheus-stack chart
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

resource "helm_release" "kube-prometheus-stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"

  depends_on = [ scaleway_k8s_pool.kube_nodepool, local_file.kubeconfig]
}


# Install Prometheus adapter to allow using prometheus metrics
# as custom metrics in Kubernetes (for Horizontal Pod Autoscaling)
# https://github.com/kubernetes-sigs/prometheus-adapter

resource "helm_release" "prometheus-adapter" {
  name = "prometheus-adapter"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "prometheus-adapter"

  # Use an external file to configure the adapter, because its syntax is quite complex.
  values = ["${file("prometheus-adapter-values.yaml")}"]

  depends_on = [ helm_release.kube-prometheus-stack ]
}

# Install Kube-eagle with helm to have a practical Grafana dashboard
# to watch K8s resources usage.
# https://github.com/cloudworkz/kube-eagle-helm-chart
# Grafana dashboard to import : https://grafana.com/grafana/dashboards/9871

resource "helm_release" "kube-eagle" {
  name = "kube-eagle"

  repository = "https://raw.githubusercontent.com/cloudworkz/kube-eagle-helm-chart/master"
  chart = "kube-eagle"

  set {
    name = "serviceMonitor.create"
    value = true
  }

  set {
    name = "serviceMonitor.releaseLabel"
    value = "kube-prometheus-stack"
  }

  depends_on = [ helm_release.kube-prometheus-stack ]
}
