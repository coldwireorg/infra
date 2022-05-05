job "cw-stolon" {
  datacenters = ["coldnet-compute", "coldnet-storage"]
  type = "system"
  priority = 100

  group "cw-stolon-server" {
    constraint {
      attribute = "${node.datacenter}"
      value = "coldnet-storage"
    }

    network {
      port "keeper" {
        static = 5432
      }
    }

    task "keeper" {
      driver = "docker"

      config {
        image = "coldwireorg/postgres:v0.0.1"
        network_mode = "host" 
        readonly_rootfs = false
        command = "/usr/local/bin/stolon-keeper"
        args = [
          "--cluster-name", "coldnet",
          "--store-backend", "consul",
          "--store-endpoints", "http://10.42.0.1:8500",
          "--data-dir", "/mnt/persist",
          "--pg-su-password", "${PG_SU_PWD}",
          "--pg-repl-username", "replicate",
          "--pg-repl-password", "${PG_REPL_PWD}",
          "--pg-listen-address", "${NOMAD_IP_keeper}",
          "--pg-port", "${NOMAD_PORT_keeper}",
          "--pg-bin-path", "/usr/lib/postgresql/14/bin/"
        ]

        ports = [ "keeper" ]
        volumes = [
          "/storage/postgres:/mnt/persist",
        ]
      }

      resources {
        memory = 1000
      }

      service {
        name = "cw-stolon-keeper"
        port = "keeper"
        address_mode = "host"
        check {
          type = "tcp"
          port = "keeper"
          interval = "60s"
          timeout = "5s"
        }
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/system/postgres/config/env.tpl"
        destination = "local/"
      }

      template {
        source = "local/env.tpl"
        destination = "secrets/env"
        env = true
      }

      vault {
        policies = ["cw-stolon"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "sentinel" {
      driver = "docker"

      config {
        image = "coldwireorg/postgres:v0.0.1"
        network_mode = "host" 
        readonly_rootfs = false
        command = "/usr/local/bin/stolon-sentinel"
        args = [
          "--cluster-name", "coldnet",
          "--store-backend", "consul",
          "--store-endpoints", "http://10.42.0.1:8500",
        ]
      }

      resources {
        memory = 100
      }
    }
  }

  group "cw-stolon-proxy" {
    network {
      port "proxy" {
        static = 6432
      }
    }

    task "proxy" {
      driver = "docker"

      config {
        image = "coldwireorg/postgres:v0.0.1"
        network_mode = "host" 
        readonly_rootfs = false
        command = "/usr/local/bin/stolon-proxy" 
        args = [
          "--cluster-name", "coldnet",
          "--store-backend", "consul",
          "--store-endpoints", "http://10.42.0.1:8500",
          "--port", "${NOMAD_PORT_proxy}",
          "--listen-address", "${NOMAD_IP_proxy}",
          "--log-level", "debug"
        ]
         ports = ["proxy"]
      }

      resources {
        memory = 100
      }

      service {
        name = "cw-stolon-proxy"
        port = "proxy"
        address_mode = "host"
        check {
          type = "tcp"
          port = "proxy"
          interval = "60s"
          timeout = "5s"
        }
      }
    }
  }
}