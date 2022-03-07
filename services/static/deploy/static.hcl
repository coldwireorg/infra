job "cw-static" {
  datacenters = ["dc1", "coldnet"]
  priority = 60

  group "cw-static-server" {
    count = 4

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "cw-static-server"
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

    task "cw-static-server" {
      env {
        SERVER_PORT = "${NOMAD_PORT_http}"
      }

      driver = "docker"

      config {
        image = "coldwireorg/static:v0.0.3"
        ports = ["http"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/static/:/static",
        ]
      }
    }
  }
}