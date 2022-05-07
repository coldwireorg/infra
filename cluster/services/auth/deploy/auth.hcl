job "cw-auth" {
  datacenters = ["dc1", "coldnet"]

  group "cw-auth" {
    count = 1

    network {
      port "auth-web" {
        to = -1
      }

      port "hydra-public" {
        to = -1
      }
      port "hydra-admin" {
        to = -1
      }
    }

    restart {
      attempts = 30
      delay = "15s"
    }

    task "auth-web" {
      driver = "docker"

      service {
        name = "cw-auth-web-server"
        port = "auth-web"

        address_mode = "host"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.cw-auth-web.rule=Host(`auth.coldwire.org`)",
          "traefik.http.routers.cw-auth-web.tls=true",
          "traefik.http.routers.cw-auth-web.tls.certresolver=coldwire",
        ]
      }

      env {
        CONFIG_FILE="/secrets/config.toml"

        SRV_PORT ="${NOMAD_PORT_auth-web}"
        HYDRA_ADDR = "${NOMAD_IP_hydra-admin}:${NOMAD_PORT_hydra-admin}"

        DB_ADDR="${NOMAD_IP_auth-web}"
        DB_PORT="6432"
      }

      config {
        image = "coldwireorg/auth:v0.3.3"
        ports = ["auth-web"]
        network_mode = "host"
      }

      artifact {
        source = "https://codeberg.org/coldwire/infra/raw/branch/main/cluster/services/auth/config/config.toml.tpl"
        destination = "local/"
      }

      template {
        source = "local/config.toml.tpl"
        destination = "secrets/config.toml"
      }

      template {
        data = <<EOH
          JWT_KEY="{{ with secret "services/data/cw-auth" }}{{ .Data.data.web_jwt_key }}{{ end }}"
        EOH

        destination = "secrets/vault.env"
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
      
      template {
        data = <<EOH
          POSTGRES_PASSWORD={{ with secret "services/data/cw-auth" }}{{ .Data.data.web_db_password }}{{ end }}
        EOH

        destination = "secrets/vault.env"
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
        URLS_LOGIN="https://auth.coldwire.org/#/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/auth/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/auth/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/#/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org"
        DB_ADDR="${NOMAD_ADDR_cw-auth-hydra-database}"
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
        data = <<EOH
          SECRETS_SYSTEM={{ with secret "services/data/cw-auth" }}{{ .Data.data.hydra_server_secret }}{{ end }}
          DSN=postgres://postgres:{{ with secret "services/data/cw-auth" }}{{ .Data.data.hydra_db_password }}{{ end }}@{{ env "DB_ADDR" }}/hydra
        EOH

        destination = "secrets/vault.env"
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
        DB_ADDR="${NOMAD_ADDR_cw-auth-hydra-database}"
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
        data = <<EOH
          SECRETS_SYSTEM={{ with secret "services/data/cw-auth" }}{{ .Data.data.hydra_server_secret }}{{ end }}
          DSN=postgres://postgres:{{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_su_password }}{{ end }}@{{ env "DB_ADDR" }}/hydra
        EOH

        destination = "secrets/vault.env"
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
