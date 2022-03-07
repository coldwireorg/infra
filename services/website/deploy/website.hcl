job "cw-website" {
  datacenters = ["dc1", "coldnet"]
  priority = 60

  group "cw-website-server" {
    count = 4

    network {
      port "cw-website-server" {
        to = -1
      }
    }

    service {
      name = "cw-website-server"
      port = "cw-website-server"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.cw-website-server.rule=Host(`coldwire.org`)",
        "traefik.http.routers.cw-website-server.tls=true",
        "traefik.http.routers.cw-website-server.tls.certresolver=coldwire",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "cw-website-server" {
      env {
        SERVER_PORT = "${NOMAD_PORT_cw-website-server}"
      }

      driver = "docker"

      config {
        image = "coldwireorg/website:v0.0.8"
        ports = ["cw-website-server"]
        network_mode = "host"
      }
    }
  }
}