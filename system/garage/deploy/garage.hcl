job "cw-garage" {
  datacenters = ["coldnet-compute", "coldnet-storage"]
  type = "system"
  priority = 100

  group "server" {
    network {
      port "s3" { static = 3900 }
      port "rpc" { static = 3901 }
      port "web" { static = 3902 }
    }

    service {
      name = "cw-garage-s3"
      port = "s3"
      address_mode = "host"
      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      env {
        SRV_IP = "${NOMAD_IP_s3}"
      }

      config {
        image = "dxflrs/arm64_garage:v0.7.0"
        command = "/garage"
        args = [ "server" ]

        ports = [
          "s3",
          "rpc",
          "web"
        ]

        network_mode = "host"

        volumes = [
          "/storage/data:/data",
          "/storage/meta:/meta",
          "secrets/config.toml:/etc/garage.toml",
        ]
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/system/garage/config/config.toml.tpl"
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
