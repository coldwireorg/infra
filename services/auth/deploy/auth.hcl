job "cw-auth" {
  datacenters = ["dc1", "coldnet"]

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
      port "web-db" {
        to = -1
      }
      port "hydra-db" {
        to = -1
      }
    }

    task "web" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = false
      }

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
        DOMAIN = "auth.coldwire.org"
        SERVER_PORT ="${NOMAD_PORT_http}"

        AUTH_SERVER_URL = "https://auth.coldwire.org"
        HYDRA_PUBLIC_URL = "https://auth.coldwire.org"
        HYDRA_ADMIN_URL = "${NOMAD_IP_hydra-admin}:${NOMAD_PORT_hydra-admin}"

        DB_URL = "postgresql://postgres:12345@${NOMAD_IP_web-db}:${NOMAD_PORT_web-db}/auth"
      }

      config {
        image = "coldwireorg/auth:v0.0.2"
        ports = ["http"]
        network_mode = "host"
      }
    }

    task "hydra-migrate" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      env {
        DSN = "postgres://postgres:12345@${NOMAD_IP_hydra-db}:${NOMAD_PORT_hydra-db}/hydra"
        SERVE_COOKIES_SAME_SITE_MODE="Lax"
        URLS_LOGIN="https://auth.coldwire.org/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org/"
      }

      config {
        image = "oryd/hydra:v1.11.7"
        network_mode = "host"

        command = "migrate"
        args = [
          "sql",
          "-e",
          "--yes",
        ]
      }
    }

    task "hydra" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = false
      }

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
        DSN = "postgres://postgres:12345@${NOMAD_IP_hydra-db}:${NOMAD_PORT_hydra-db}/hydra"
        SECRETS_SYSTEM = "ThisIsJustASuperToken!"
        SERVE_COOKIES_SAME_SITE_MODE="Lax"
        URLS_LOGIN="https://auth.coldwire.org/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org/"
      }

      config {
        image = "oryd/hydra:v1.11.7"
        ports = ["hydra-public", "hydra-admin"]
        network_mode = "host"

        command = "serve"
        args = [
          "all"
        ]
      }
    }

    task "web-db" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "12345"
        POSTGRES_DB = "auth"
        PGPORT = "${NOMAD_PORT_web-db}"
      }

      config {
        image = "postgres:latest"
        ports = ["web-db"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/auth/web/database:/var/lib/postgresql/data",
          "local/tables.sql:/docker-entrypoint-initdb.d/tables.sql",
        ]
      }

      service {
        name = "cw-auth-web-postgres"
        port = "web-db"

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
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/auth/config/tables.sql"
        destination = "local/"
      }
    }

    task "hydra-db" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "12345"
        POSTGRES_DB = "hydra"
        PGPORT = "${NOMAD_PORT_hydra-db}"
      }

      config {
        image = "postgres:latest"
        ports = ["hydra-db"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/auth/hydra/database:/var/lib/postgresql/data",
        ]
      }

      service {
        name = "cw-auth-hydra-postgres"
        port = "hydra-db"

        address_mode = "host"

        check {
          type     = "script"
          command = "pg_isready"
          args = ["-q", "-d", "postgres", "-U", "postgres"]
          interval = "10s"
          timeout  = "45s"
        }
      }
    }
  }
}