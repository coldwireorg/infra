job "cw-static" {
  datacenters = ["dc1", "coldnet"]
  priority = 60

  group "cw-static-server" {
    count = 4

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    network {
      port "cw-static-server" {
        to = -1
      }
    }

    service {
      name = "cw-static-server"
      port = "cw-static-server"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.cw-static-server.rule=(Host(`static.coldwire.org`) || (Host(`coldwire.org`) && Path(`/.well-known/matrix/client`)))",
        "traefik.http.routers.cw-static-server.tls=true",
        "traefik.http.routers.cw-static-server.tls.certresolver=coldwire",
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
        SERVER_PORT = "${NOMAD_PORT_cw-static-server}"
      }

      driver = "docker"

      config {
        image = "coldwireorg/static:v0.0.3"
        ports = ["cw-static-server"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/static/:/static",
        ]
      }
    }
  }
}
