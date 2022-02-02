job "coldwire-website" {
  datacenters = ["dc1", "coldwire"]

  group "website" {
    count = 2

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "coldwire-website"
      port = "http"

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

      driver = "podman"

      config {
        image = "docker://coldwireorg/website"
        ports = ["http"]
      }
    }
  }
}
