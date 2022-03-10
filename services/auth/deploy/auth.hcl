job "cw-auth" {
  datacenters = ["dc1", "coldnet"]

  group "cw-auth" {
    count = 1

    network {
      port "cw-auth-web-server" {
        to = -1
      }
      port "cw-auth-web-database" {
        to = -1
      }

      port "cw-auth-hydra-public" {
        to = -1
      }
      port "cw-auth-hydra-admin" {
        to = -1
      }
      port "cw-auth-hydra-database" {
        to = -1
      }
    }

    restart {
      attempts = 30
      delay    = "15s"
    }

    task "cw-auth-web-server" {
      driver = "docker"

      service {
        name = "cw-auth-web-server"
        port = "cw-auth-web-server"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-auth-web-server.rule=Host(`auth.coldwire.org`)",
          "traefik.http.routers.cw-auth-web-server.tls=true",
          "traefik.http.routers.cw-auth-web-server.tls.certresolver=coldwire",
        ]
      }

      env {
        DOMAIN = "auth.coldwire.org"
        SERVER_PORT ="${NOMAD_PORT_cw-auth-web-server}"

        AUTH_SERVER_URL = "https://auth.coldwire.org"
        HYDRA_PUBLIC_URL = "https://auth.coldwire.org/"
        HYDRA_ADMIN_URL = "${NOMAD_IP_cw-auth-hydra-admin}:${NOMAD_PORT_cw-auth-hydra-admin}"
      }

      config {
        image = "coldwireorg/auth:v0.0.10"
        ports = ["cw-auth-web-server"]
        network_mode = "host"
      }

      template {
        data = <<EOF
          {{ with secret "services/cw-auth" }}
          DSN = "postgres://postgres:{{ index .Data "web-db-password" }}@{{ env "NOMAD_IP_cw-auth-web-database" }}:{{ env "NOMAD_PORT_cw-auth-web-database" }}/auth"
          {{ end }}
        EOF

        destination = "secrets/cw-auth-web-server.env"
        env = true
      }

      vault {
        policies = ["cw-auth"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
    
    task "cw-auth-web-database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_DB = "auth"
        PGPORT = "${NOMAD_PORT_cw-auth-web-database}"
      }

      config {
        image = "postgres:latest"
        ports = ["cw-auth-web-database"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/auth/web/database:/var/lib/postgresql/data",
          "local/tables.sql:/docker-entrypoint-initdb.d/tables.sql",
        ]
      }

      service {
        name = "cw-auth-web-database"
        port = "cw-auth-web-database"

        address_mode = "host"

        check {
          type     = "script"
          command = "pg_isready"
          args = ["-q", "-d", "postgres", "-U", "postgres"]
          interval = "10s"
          timeout  = "120s"
        }
      }
      
      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/services/auth/config/tables.sql"
        destination = "local/"
      }

      template {
        data = <<EOF
          {{ with secret "services/cw-auth" }}
          POSTGRES_PASSWORD = {{ index .Data "web-db-password" }}
          {{ end }}
        EOF

        destination = "secrets/cw-auth-web-database.env"
        env = true
      }

      vault {
        policies = ["cw-auth"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "cw-auth-hydra-server" {
      driver = "docker"

      service {
        name = "cw-auth-hydra-server"
        port = "cw-auth-hydra-public"

        address_mode = "host"

        tags = [       
          "traefik.enable=true",
          "traefik.http.routers.cw-auth-hydra.rule=Host(`auth.coldwire.org`) && (PathPrefix(`/oauth2`) || PathPrefix(`/.well-known`) || PathPrefix(`/userinfo`))",
          "traefik.http.routers.cw-auth-hydra.tls=true",
          "traefik.http.routers.cw-auth-hydra.tls.certresolver=coldwire",
        ]
      }

      env {
        SERVE_COOKIES_SAME_SITE_MODE="Lax"
        SERVE_ADMIN_PORT="${NOMAD_PORT_cw-auth-hydra-admin}"
        SERVE_PUBLIC_PORT="${NOMAD_PORT_cw-auth-hydra-public}"
        URLS_LOGIN="https://auth.coldwire.org/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org"
      }

      config {
        image = "oryd/hydra:v1.11.7"
        ports = ["cw-auth-hydra-public", "cw-auth-hydra-admin"]
        network_mode = "host"

        command = "serve"
        args = [
          "all",
          "--sqa-opt-out",
          "--dangerous-force-http",
        ]
      }

      template {
        data = <<EOF
          {{ with secret "services/cw-auth" }}
          SECRETS_SYSTEM="{{ index .Data "hydra-server-secret" }}"
          DSN = "postgres://postgres:{{ index .Data "hydra-db-password" }}@{{ env "NOMAD_IP_cw-auth-hydra-database" }}:{{ env "NOMAD_PORT_cw-auth-hydra-database" }}/hydra"
          {{ end }}
        EOF

        destination = "secrets/cw-auth-hydra-server.env"
        env = true
      }

      vault {
        policies = ["cw-auth"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "cw-auth-hydra-migrate" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      env {
        SERVE_COOKIES_SAME_SITE_MODE="Lax"
        SERVE_ADMIN_PORT="${NOMAD_PORT_cw-auth-hydra-admin}"
        SERVE_PUBLIC_PORT="${NOMAD_PORT_cw-auth-hydra-public}"
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

      template {
        data = <<EOF
          {{ with secret "services/cw-auth" }}
          SECRETS_SYSTEM="{{ index .Data "hydra-server-secret" }}"
          DSN = "postgres://postgres:{{ index .Data "hydra-db-password" }}@{{ env "NOMAD_IP_cw-auth-hydra-database" }}:{{ env "NOMAD_PORT_cw-auth-hydra-database" }}/hydra"
          {{ end }}
        EOF

        destination = "secrets/cw-auth-hydra-migrate.env"
        env = true
      }

      vault {
        policies = ["cw-auth"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }

    task "cw-auth-hydra-database" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_DB = "hydra"
        PGPORT = "${NOMAD_PORT_cw-auth-hydra-database}"
      }

      config {
        image = "postgres:latest"
        ports = ["cw-auth-hydra-database"]
        network_mode = "host"

        volumes = [
          "/mnt/storage/services/auth/hydra/database:/var/lib/postgresql/data",
        ]
      }

      service {
        name = "cw-auth-hydra-database"
        port = "cw-auth-hydra-database"

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
        data = <<EOF
          {{ with secret "services/cw-auth" }}
          POSTGRES_PASSWORD = {{ index .Data "hydra-db-password" }}
          {{ end }}
        EOF

        destination = "secrets/cw-auth-hydra-database.env"
        env = true
      }

      vault {
        policies = ["cw-auth"]
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}