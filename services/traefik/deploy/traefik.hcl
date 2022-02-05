job "traefik" {
  datacenters = ["dc1", "coldnet"]
  type = "service"

  group "traefik" {
    count = 6

    network {
      port "http" {
        static = 80
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik"

      check {
        name = "alive"
        type = "tcp"
        port = "http"
        interval = "10s"
        timeout = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:latest"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOH
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.traefik]
    address = ":8081"

[api]
    dashboard = true
    insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.consulCatalog.endpoint]
      address = "10.42.0.1:8500"
      scheme  = "http"
        EOH
        destination = "local/traefik.toml"
      }
    }
  }
}
