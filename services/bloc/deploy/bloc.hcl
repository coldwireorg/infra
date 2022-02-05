job "bloc" {
  datacenters = ["dc1", "coldnet"]

  group "bloc-front" {
    count = 4

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
        "traefik.http.routers.http.rule=Host(`dev.bloc.coldwire.org`) || Host(`bloc.coldwire.org`)",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "backend" {
      driver = "docker"

      env {
        API_BASE = "https://api.bloc.coldwire.org"
      }

      config {
        image = "coldwireorg/bloc-frontend:v0.1.0"
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
          "traefik.http.routers.http.rule=Host(`dev.api.bloc.coldwire.org`) || Host(`api.bloc.coldwire.org`)",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
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
        image = "coldwireorg/bloc-backend:v0.1.0"
        ports = ["http"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/bloc:/storage"
        ]
      }
    }

    task "database" {
      driver = "docker"

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
          "/mnt/storage/bloc/database:/data/db",
          "/local/init.sh:/docker-entrypoint-initdb.d/"
          "/local/tables.sql:/docker-entrypoint-initdb.d/"
        ]
      }

      service {
        name = "postgresql"
        port = "postgresql"

        address_mode = "host"

        check {
          type     = "script"
          command = "pg_isready"
          args = ["-q", "-d", "postgres", "-U", "postgres"]
          interval = "10s"
          timeout  = "45s"
        }
      }

      template {
        source = "../config/init.sh"
        destination = "local/init.sh"
      }

      template {
        source = "../config/tables.sql"
        destination = "local/tables.sql"
      }
    }
  }
}