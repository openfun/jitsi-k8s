resource "scaleway_domain_record" "meet_domain_record" {
  dns_zone = "scaling.just1not2.org"
  name     = lookup(var.jitsi_dns_name, terraform.workspace, "meet")
  type     = "A"
  data     = scaleway_lb_ip.ingress_lb_ip.ip_address
  ttl      = 3600

  depends_on = [ scaleway_lb_ip.ingress_lb_ip ]
}

resource "scaleway_domain_record" "grafana_domain_record" {
  dns_zone = "scaling.just1not2.org"
  name     = lookup(var.grafana_dns_name, terraform.workspace, "grafana")
  type     = "A"
  data     = scaleway_lb_ip.ingress_lb_ip.ip_address
  ttl      = 3600

  depends_on = [ scaleway_lb_ip.ingress_lb_ip ]
}
