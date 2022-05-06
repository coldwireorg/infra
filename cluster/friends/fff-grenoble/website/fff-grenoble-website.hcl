job "fge-website" {
  datacenters = ["coldnet-compute"]
  priority = 60

  group "fge-website-frontend" {
    count = 2

    service {
      name = "fge-website-frontend-server"
      port = "fge-website-frontend-server"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.fge-website-frontend-server.rule=Host(`fffgrenoble.fr`)",
        "traefik.http.routers.fge-website-frontend-server.tls=true",
        "traefik.http.routers.fge-website-frontend-server.tls.certresolver=coldwire",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    network {
      port "fge-website-frontend-server" {
        to = -1
      }
    }

    task "fge-website-frontend-server" {
      driver = "docker"

      env {
        PORT = "${NOMAD_PORT_fge-website-frontend-server}"
      }

      config {
        image = "coldwireorg/fffgrenoble-site:v0.1.7"
        ports = ["fge-website-frontend-server"]
        network_mode = "host"
      }
    }
  }
}
