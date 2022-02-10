job "coldwire-website" {
  datacenters = ["dc1", "coldnet"]
  priority = 60

  group "website" {
    count = 4

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
        "traefik.http.routers.http.rule=Host(`coldwire.org`)",
        "traefik.http.routers.cw-website.rule=Host(`coldwire.org`)",
        "traefik.http.routers.cw-website.tls=true",
        "traefik.http.routers.cw-website.tls.certresolver=coldwire",
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