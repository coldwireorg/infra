job "cw-garage" {
  datacenters = ["coldnet-storage"]
  type = "system"
  priority = 100

  group "cw-garage" {
    network {
      port "cw-garage-server" {
        static = 3901
      }

      port "cw-garage-s3" {
        static = 3900
      }
    }

    service {
      name = "cw-garage"
      port = "cw-garage-server"

      address_mode = "host"

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "cw-garage-server" {
      driver = "docker"

      env {
        SRV_IP = "${NOMAD_IP_cw-garage-server}"
      }

      config {
        image = "dxflrs/arm64_garage:v0.7.0"
        command = "/garage"
        args = [ "server" ]

        ports = [
          "cw-storage-garage",
          "cw-storage-s3"
        ]

        network_mode = "host"

        volumes = [
          "/storage/data:/data",
          "/storage/meta:/meta",
          "secrets/config.toml:/etc/garage.toml",
        ]
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/storage/garage/config.toml.tpl"
        destination = "local/"
      }

      template {
        source = "local/config.toml.tpl"
        destination = "secrets/config.toml"
      }

      vault {
        policies = ["cw-garage"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
