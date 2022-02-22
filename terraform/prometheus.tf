# Prompt the Grafana admin password
variable "grafana_password" {
  type        = string
  description = "Password of the Grafana web interface"
}

# Prompt the Grafana domain name
variable "grafana_domain_name" {
  type        = string
  description = "Domain name of the Grafana web interface"
}

# Install the helm kube-prometheus-stack chart
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

resource "helm_release" "kube-prometheus-stack" {
  name = "kube-prometheus-stack"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"

  set {
    name = "alertmanager.alertmanagerSpec.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  set {
    name = "prometheusOperator.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  set {
    name = "prometheus.prometheusSpec.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  set {
    name = "grafana.nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  # MONITORING OPTIONS
  set {
    name = "grafana.adminPassword"
    value = var.grafana_password
  }

  set {
    name = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    name = "grafana.ingress.hosts"
    value = "{${var.grafana_domain_name}}"
  }

  set {
    name = "grafana.ingress.enabled"
    value = "true"
  }

  depends_on = [ scaleway_k8s_pool.default, local_file.kubeconfig, scaleway_domain_record.grafana_domain_record ]
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

  set {
    name = "nodeSelector.k8s\\.scaleway\\.com/pool-name"
    value = "default"
  }

  depends_on = [ helm_release.kube-prometheus-stack ]
}
