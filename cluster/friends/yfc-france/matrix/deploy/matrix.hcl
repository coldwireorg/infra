job "yfcfr-matrix" {
  datacenters = ["coldnet"]
  priority = 60

  group "yfcfr-matrix" {
    count = 1

    network {
      port "yfcfr-matrix-synapse" {
        to = -1
      }
      port "yfcfr-matrix-element" {
        to = 80
      }
      port "yfcfr-matrix-database" {
        to = -1
      }
    }

    restart {
      attempts = 30
      delay    = "15s"
    }

    task "yfcfr-matrix-synapse" {
      driver = "docker"

      service {
        name = "yfcfr-matrix-synapse"
        port = "yfcfr-matrix-synapse"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.yfcfr-matrix-synapse.rule=Host(`matrix.fffgrenoble.fr`)",
          "traefik.http.routers.yfcfr-matrix-synapse.tls=true",
          "traefik.http.routers.yfcfr-matrix-synapse.tls.certresolver=coldwire",
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
        ports = ["yfcfr-matrix-synapse"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/friends/yfc-france/matrix/synapse/:/data",
        ]
      }

      env {
        SYNAPSE_CONFIG_DIR="${NOMAD_SECRETS_DIR}"
        MATRIX_PORT="${NOMAD_PORT_yfcfr-matrix-synapse}"
        MATRIX_DB_ADDR="${NOMAD_IP_yfcfr-matrix-database}"
        MATRIX_DB_PORT="${NOMAD_PORT_yfcfr-matrix-database}"
        GID=0
        UID=0
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/friends/yfc-france/matrix/config/homeserver.yaml"
        destination = "local/"
      }

      template {
        left_delimiter = "(|"
        right_delimiter = "|)"
        source = "local/homeserver.yaml"
        destination = "secrets/homeserver.yaml"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/friends/yfc-france/matrix/config/matrix.fffgrenoble.fr.signing.key"
        destination = "local/"
      }

      template {
        source = "local/matrix.fffgrenoble.fr.signing.key"
        destination = "secrets/matrix.fffgrenoble.fr.signing.key"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/friends/yfc-france/matrix/config/matrix.fffgrenoble.fr.log.config"
        destination = "secrets/"
      }

      vault {
        policies = ["yfcfr-matrix"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "yfcfr-matrix-database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_INITDB_ARGS="--no-locale --encoding=UTF8"
        POSTGRES_USER = "synapse"
        POSTGRES_DB = "synapse"
        PGPORT = "${NOMAD_PORT_yfcfr-matrix-database}"
      }

      config {
        image = "postgres:latest"
        ports = ["yfcfr-matrix-database"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/friends/yfc-france/matrix/database:/var/lib/postgresql/data",
        ]
      }

      service {
        name = "yfcfr-matrix-database"
        port = "yfcfr-matrix-database"

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
          POSTGRES_PASSWORD={{ with secret "friends/data/yfcfr-matrix" }}{{ .Data.data.db_password }}{{ end }}
        EOH

        destination = "secrets/vault.env"
        env = true
      }

      vault {
        policies = ["yfcfr-matrix"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "yfcfr-matrix-element" {
      driver = "docker"

      service {
        name = "yfcfr-matrix-element"
        port = "yfcfr-matrix-element"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.yfcfr-matrix-element.rule=Host(`chat.fffgrenoble.fr`)",
          "traefik.http.routers.yfcfr-matrix-element.tls=true",
          "traefik.http.routers.yfcfr-matrix-element.tls.certresolver=coldwire",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }

      config {
        image = "dotwee/element-web:latest"
        ports = ["yfcfr-matrix-element"]

        volumes = [
          "local/element.json:/etc/element-web/config.json"
        ]
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/friends/yfc-france/matrix/config/element.json"
        destination = "local/"
      }
    }
  }
}