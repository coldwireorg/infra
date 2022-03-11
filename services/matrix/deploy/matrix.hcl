job "cw-matrix" {
  datacenters = ["coldnet"]
  priority = 60

  group "cw-matrix" {
    count = 1

    network {
      port "cw-matrix-synapse" {
        to = -1
      }
      port "cw-matrix-element" {
        to = -1
      }
      port "cw-matrix-database" {
        to = -1
      }
    }

    restart {
      attempts = 30
      delay    = "15s"
    }

    task "cw-matrix-synapse" {
      driver = "docker"

      service {
        name = "cw-matrix-synapse"
        port = "cw-matrix-synapse"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-matrix-synapse.rule=Host(`matrix.coldwire.org`)",
          "traefik.http.routers.cw-matrix-synapse.tls=true",
          "traefik.http.routers.cw-matrix-synapse.tls.certresolver=coldwire",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }

      config {
        image = "matrixdotorg/synapse:latest"
        ports = ["cw-matrix-synapse"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/matrix/synapse/:/data",
          "secrets/"
        ]
      }

      env {
        MATRIX_PORT="${NOMAD_PORT_cw-matrix-synapse}"
        MATRIX_DB_ADDR="${NOMAD_ADDR_cw-matrix-database}"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/matrix/config/homeserver.yaml"
        destination = "local/"
      }

      template {
        left_delimiter = "(|"
        right_delimiter = "|)"
        source = "local/homeserver.yaml"
        destination = "secrets/homeserver.yaml"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/matrix/config/matrix.coldwire.org.signing.key"
        destination = "local/"
      }

      template {
        source = "local/matrix.coldwire.org.signing.key"
        destination = "secrets/matrix.coldwire.org.signing.key"
      }

      vault {
        policies = ["cw-matrix"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "cw-matrix-database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "synapse"
        POSTGRES_DB = "synapse"
        PGPORT = "${NOMAD_PORT_cw-matrix-database}"
      }

      config {
        image = "postgres:latest"
        ports = ["cw-matrix-database"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/matrix/database:/var/lib/postgresql/data",
        ]
      }

      service {
        name = "cw-matrix-database"
        port = "cw-matrix-database"

        address_mode = "host"

        check {
          type     = "script"
          command = "pg_isready"
          args = ["-q", "-d", "postgres", "-U", "postgres"]
          interval = "10s"
          timeout  = "120s"
        }
      }
      
      template {
        data = <<EOH
          POSTGRES_PASSWORD={{ with secret "services/data/cw-matrix" }}{{ .Data.data.synapse_db_password }}{{ end }}
        EOH

        destination = "secrets/vault.env"
        env = true
      }

      vault {
        policies = ["cw-matrix"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "cw-matrix-element" {
      driver = "docker"

      service {
        name = "cw-matrix-element"
        port = "cw-matrix-element"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-matrix-element.rule=Host(`organize.coldwire.org`)",
          "traefik.http.routers.cw-matrix-element.tls=true",
          "traefik.http.routers.cw-matrix-element.tls.certresolver=coldwire",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }

      config {
        image = "bubuntux/element-web:latest"
        ports = ["cw-matrix-element"]
        network_mode = "host"

        volumes = [
          "local/element.json:/app/config.json"
        ]
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/matrix/config/element.json"
        destination = "local/"
      }
    }
  }
}