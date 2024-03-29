job "cw-website" {
  datacenters = ["coldnet-compute"]
  priority = 60

  group "cw-website-server" {
    count = 4

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    network {
      port "cw-website-server" {
        static = "1313"
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
      driver = "docker"

      config {
        image = "coldwireorg/website:v0.1.4"
        ports = ["cw-website-server"]
        network_mode = "host"
      }
    }
  }
}
