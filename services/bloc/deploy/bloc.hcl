job "bloc" {
  datacenters = ["dc1", "coldnet"]
  priotity = 80

  group "bloc-front" {
    count = 2

    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "bloc-frontend"
      port = "http"

      address_mode = "host"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.blocfrontend.rule=Host(`bloc.coldwire.org`)",
        "traefik.http.routers.cw-bloc-front.rule=Host(`bloc.coldwire.org`)",
        "traefik.http.routers.cw-bloc-front.tls=true",
        "traefik.http.routers.cw-bloc-front.tls.certresolver=coldwire",

      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "frontend" {
      driver = "docker"

      env {
        PORT = "${NOMAD_PORT_http}"
      }

      config {
        image = "coldwireorg/bloc-frontend:v0.1.4"
        ports = ["http"]
        network_mode = "host"
      }
    }
  }

  group "bloc-backend" {
    count = 1

    network {
      port "http" {
        to = -1
      }
      port "postgres" {
        to = 5432
      }
    }

    task "backend" {
      driver = "docker"

      service {
        name = "bloc-backend"
        port = "http"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.blocbackend.rule=(Host(`bloc.coldwire.org`) && PathPrefix(`/api`))",
          "traefik.http.routers.cw-bloc-back.rule=(Host(`bloc.coldwire.org`) && PathPrefix(`/api`))",
          "traefik.http.routers.cw-bloc-back.tls=true",
          "traefik.http.routers.cw-bloc-back.tls.certresolver=coldwire",
          "traefik.http.middlewares.limit.buffering.maxRequestBodyBytes=30746254628"
        ]
      }

      env {
        SERVER_PORT = "${NOMAD_PORT_http}"
        DB_URL = "postgresql://${NOMAD_IP_postgres}:${NOMAD_PORT_postgres}/bloc?user=postgres&password=12345"
        STORAGE_DIR = "/storage"
        SERVER_DOMAIN = "coldwire.org"
        SERVER_HTTPS = true
        STORAGE_QUOTA = 4096
      }

      config {
        image = "coldwireorg/bloc-backend:v0.1.1"
        ports = ["http"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/bloc/storage:/storage"
        ]
      }
    }

    task "database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "12345"
        POSTGRES_DB = "bloc" 
      }

      config {
        image = "postgres:latest"
        ports = ["postgres"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/bloc/database:/var/lib/postgresql/data",
          "/local/:/docker-entrypoint-initdb.d/",
        ]
      }

      service {
        name = "postgresql"
        port = "postgres"

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
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/bloc/config/init.sh"
        destination = "local/"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/bloc/config/tables.sql"
        destination = "local/"
      }
    }
  }
}