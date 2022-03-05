job "cw-auth" {
  datacenters = ["dc1", "coldnet"]
  priotity = 80

  group "cw-auth" {
    count = 1

    network {
      port "http" {
        to = -1
      }
      port "hydra-public" {
        to = 4444
      }
      port "hydra-admin" {
        to = 4445
      }
      port "postgres" {
        to = 5432
      }
    }

    task "web" {
      driver = "docker"

      service {
        name = "cw-auth-web"
        port = "http"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-auth-web.rule=Host(`auth.coldwire.org`)",
          "traefik.http.routers.cw-auth-web.tls=true",
          "traefik.http.routers.cw-auth-web.tls.certresolver=coldwire",
        ]
      }

      env {
        HYDRA_ADMIN_URL = "http://${NOMAD_IP_hydra-admin}:${NOMAD_PORT_hydra-admin}"
        SERVER_PORT = "${NOMAD_PORT_http}"
        DB_URL = "postgresql://postgres:12345@${NOMAD_IP_postgres}:${NOMAD_PORT_postgres}/auth"
      }

      config {
        image = "coldwireorg/auth:v0.0.1"
        ports = ["http"]
        network_mode = "host"
      }
    }

    task "hydra" {
      driver = "docker"

      service {
        name = "cw-auth-hydra"
        port = "http"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-auth-hydra.rule=(Host(`auth.coldwire.org`) && PathPrefix(`/oauth`))",
          "traefik.http.routers.cw-auth-hydra.tls=true",
          "traefik.http.routers.cw-auth-hydra.tls.certresolver=coldwire",
          "traefik.http.routers.cw-auth-hydra.loadbalancer.server.port=${NOMAD_PORT_hydra-public}",
        ]
      }

      env {
        DSN = "postgres://postgres:12345@${NOMAD_IP_postgres}:${NOMAD_PORT_postgres}/hydra"
      }

      config {
        image = "oryd/hydra:v1.11.7"
        ports = ["hydra-public", "hydra-admin"]
        network_mode = "host"

        command = "/usr/bin/hydra"
        args = [
          "serve"
          "-c"
          "/etc/config/hydra/hydra.yml"
          "all"
        ]

        volumes = [
          "/local/:/etc/config/hydra/",
        ]
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/auth/config/hydra.yaml"
        destination = "local/"
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
        POSTGRES_DB = "hydra" 
      }

      config {
        image = "postgres:latest"
        ports = ["postgres"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/auth/database:/var/lib/postgresql/data",
          "/local/:/docker-entrypoint-initdb.d/",
        ]
      }

      service {
        name = "cw-auth-postgres"
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
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/auth/config/init.sh"
        destination = "local/"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/auth/config/tables.sql"
        destination = "local/"
      }
    }
  }
}