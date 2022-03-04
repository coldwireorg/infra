job "coldwire-static" {
  datacenters = ["dc1", "coldnet"]
  priority = 60

  group "static" {
    count = 4

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "static"
      port = "http"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.cw-static.rule=Host(`static.coldwire.org`)",
        "traefik.http.routers.cw-static.tls=true",
        "traefik.http.routers.cw-static.tls.certresolver=coldwire",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "static" {
      env {
        SERVER_PORT = "${NOMAD_PORT_http}"
      }

      driver = "docker"

      config {
        image = "coldwireorg/static:v0.0.1"
        ports = ["http"]
        network_mode = "host"
      }
    }
  }
}