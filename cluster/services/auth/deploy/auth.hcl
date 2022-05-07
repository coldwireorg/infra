job "cw-auth" {
  datacenters = ["coldnet-compute"]

  group "cw-auth" {
    count = 1

    network {
      port "web" {
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

    task "web" {
      driver = "docker"

      service {
        name = "cw-auth-web"
        port = "web"

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

        DB_ADDR="${attr.unique.network.ip-address}"
        DB_PORT="6432"
      }

      config {
        image = "coldwireorg/auth:v0.3.6"
        ports = ["web"]
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

    task "hydra" {
      driver = "docker"

      service {
        name = "cw-auth-hydra"
        port = "hydra-public"

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
        SERVE_ADMIN_PORT="${NOMAD_PORT_hydra-admin}"
        SERVE_PUBLIC_PORT="${NOMAD_PORT_hydra-public}"
        URLS_LOGIN="https://auth.coldwire.org/#/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/auth/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/auth/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/#/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org"
        DB_ADDR="${attr.unique.network.ip-address}:6432"
      }

      config {
        image = "oryd/hydra:v1.11.8"
        ports = ["hydra-public", "hydra-admin"]
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
          DSN=postgres://postgres:{{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_su_password }}{{ end }}@{{ env "DB_ADDR" }}/cw_hydra
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

    task "hydra-migrate" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      env {
        SERVE_COOKIES_SAME_SITE_MODE="Lax"
        SERVE_ADMIN_PORT="${NOMAD_PORT_hydra-admin}"
        SERVE_PUBLIC_PORT="${NOMAD_PORT_hydra-public}"
        URLS_LOGIN="https://auth.coldwire.org/sign-in"
        URLS_CONSENT="https://auth.coldwire.org/api/consent"
        URLS_LOGOUT="https://auth.coldwire.org/api/logout"
        URLS_POST_LOGOUT_REDIRECT="https://auth.coldwire.org/sign-in"
        URLS_SELF_ISSUER="https://auth.coldwire.org/"
        DB_ADDR="${attr.unique.network.ip-address}:6432"
      }

      config {
        image = "oryd/hydra:v1.11.8"
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
          DSN=postgres://postgres:{{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_su_password }}{{ end }}@{{ env "DB_ADDR" }}/cw_hydra
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
