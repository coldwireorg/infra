job "cw-storage" {
  datacenters = ["coldnet-storage"]
  type = "system"
  priority = 100

  group "cw-storage-server" {
    network {
      port "cw-storage-garage" {
        static = 3901
      }

      port "cw-storage-s3" {
        static = 3900
      }
    }

    service {
      name = "cw-storage-garage"
      port = "cw-storage-garage"

      address_mode = "host"

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "cw-storage-garage" {
      env {
        SRV_IP = "${NOMAD_IP_cw-storage-garage}"
      }

      config {
        image = "dxflrs/arm64_garage:v0.7.0"
        ports = ["cw-storage-garage" "cw-storage-s3"]
        network_mode = "host"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/storage/config.toml.tpl"
        destination = "local/"
      }

      template {
        source = "local/config.toml.tpl"
        destination = "secrets/config.toml"
      }

      vault {
        policies = ["cw-storage"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
