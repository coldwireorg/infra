job "coldwire-website" {
  datacenters = ["dc1", "coldnet"]

  group "website" {
    count = 2

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "website"
      port = "http"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`dev.coldwire.org`) || Host(`coldwire.org`)",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "website" {
      env {
        SERVER_PORT = "${NOMAD_PORT_http}"
      }

      driver = "docker"

      config {
        image = "coldwireorg/website:v0.0.8"
        ports = ["http"]
        network_mode = "host"
      }
    }
  }
}