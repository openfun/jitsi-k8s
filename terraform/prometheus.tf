
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

  # Add Jitsi-Meet dashboards to Grafana
  # Dashboards are fetched from https://github.com/systemli/prometheus-jitsi-meet-exporter/tree/1.2.0/dashboards
  # Values are merged with https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
  set {
    name = "grafana.dashboardProviders.dashboardproviders\\.yaml.apiVersion"
    value = 1
  }

  set {
    name = "grafana.dashboardProviders.dashboardproviders\\.yaml.providers[0].name"
    value = "jitsi"
  }

  set {
    name = "grafana.dashboardProviders.dashboardproviders\\.yaml.providers[0].orgId"
    value = 1
  }

  set {
    name = "grafana.dashboardProviders.dashboardproviders\\.yaml.providers[0].options.path"
    value = "/var/lib/grafana/dashboards/jitsi"
  }

  set {
    name = "grafana.dashboards.jitsi.jitsi-meet.url"
    value = "https://raw.githubusercontent.com/systemli/prometheus-jitsi-meet-exporter/1.2.0/dashboards/jitsi-meet.json"
  }

  set {
    name = "grafana.dashboards.jitsi.jitsi-meet.datasource"
    value = "Prometheus"
  }

  set {
    name = "grafana.dashboards.jitsi.jitsi-meet-system.url"
    value = "https://raw.githubusercontent.com/systemli/prometheus-jitsi-meet-exporter/1.2.0/dashboards/jitsi-meet-system.json"
  }

  set {
    name = "grafana.dashboards.jitsi.jitsi-meet-system.datasource"
    value = "Prometheus"
  }

  depends_on = [ scaleway_k8s_pool.default, local_file.kubeconfig ]
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
