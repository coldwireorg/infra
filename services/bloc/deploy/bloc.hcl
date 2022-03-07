job "cw-bloc" {
  datacenters = ["dc1", "coldnet"]

  group "cw-bloc-front" {
    count = 2

    network {
      port "cw-bloc-front-server" {
        to = -1
      }
    }

    service {
      name = "cw-bloc-front"
      port = "cw-bloc-front-server"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.cw-bloc-front-server.rule=Host(`bloc.coldwire.org`)",
        "traefik.http.routers.cw-bloc-front-server.tls=true",
        "traefik.http.routers.cw-bloc-front-server.tls.certresolver=coldwire",

      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "cw-bloc-front-server" {
      driver = "docker"

      env {
        PORT = "${NOMAD_PORT_cw-bloc-front-server}"
      }

      config {
        image = "coldwireorg/bloc-frontend:v0.1.4"
        ports = ["cw-bloc-front-server"]
        network_mode = "host"
      }
    }
  }

  group "cw-bloc-back-server" {
    count = 1

    network {
      port "cw-bloc-back-server" {
        to = -1
      }
      port "cw-bloc-back-database" {
        to = -1
      }
    }

    task "cw-bloc-back-server" {
      driver = "docker"

      service {
        name = "cw-bloc-back-server"
        port = "cw-bloc-back-server"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-bloc-back-server.rule=(Host(`bloc.coldwire.org`) && PathPrefix(`/api`))",
          "traefik.http.routers.cw-bloc-back-server.tls=true",
          "traefik.http.routers.cw-cw-bloc-back-server.certresolver=coldwire",
          "traefik.http.middlewares.limit.buffering.maxRequestBodyBytes=30746254628"
        ]
      }

      env {
        SERVER_PORT = "${NOMAD_PORT_cw-bloc-back-server}"
        DB_URL = "postgresql://${NOMAD_IP_cw-bloc-back-database}:${NOMAD_PORT_cw-bloc-back-database}/bloc?user=postgres&password=12345"
        STORAGE_DIR = "/storage"
        SERVER_DOMAIN = "coldwire.org"
        SERVER_HTTPS = true
        STORAGE_QUOTA = 4096
      }

      config {
        image = "coldwireorg/bloc-backend:v0.1.1"
        ports = ["cw-bloc-back-server"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/bloc/storage:/storage"
        ]
      }
    }

    task "cw-bloc-back-database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "12345"
        POSTGRES_DB = "bloc"
        PGPORT = "${NOMAD_PORT_cw-bloc-back-database}"
      }

      config {
        image = "postgres:latest"
        ports = ["cw-bloc-back-database"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/bloc/database:/var/lib/postgresql/data",
          "local/tables.sql:/docker-entrypoint-initdb.d/tables.sql",
        ]
      }

      service {
        name = "cw-bloc-back-database"
        port = "cw-bloc-back-database"

        address_mode = "host"

        check {
          type     = "script"
          command = "pg_isready"
          args = ["-q", "-d", "postgres", "-U", "postgres"]
          interval = "10s"
          timeout  = "45s"
        }
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/bloc/config/tables.sql"
        destination = "local/"
      }
    }
  }
}