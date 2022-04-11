nomad {
  address = "http://10.42.0.1:4646"
}

telemetry {
  prometheus_metrics = true
  disable_hostname   = true
}

apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "http://prometheus.opstreelabs.in:9090"
  }
}

strategy "target-value" {
  driver = "target-value"
}