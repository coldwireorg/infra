[server]
address = "0.0.0.0"
port = "{{ env "SRV_PORT" }}"
auth-url = "https://auth.coldwire.org"
auth-secret = "{{ with secret "services/data/cw-oidc-secrets" }}{{ .Data.data.cw_auth }}{{ end }}"

[database]
driver = "postgres"

  [database.postgres]
  address = "{{ env "DB_ADDR" }}"
  port = "{{ env "DB_PORT" }}"
  user = "postgres"
  password = "{{ with secret "services/data/cw-auth" }}{{ .Data.data.web_db_password }}{{ end }}"
  name = "auth"

[hydra]
admin = "http://{{ env "HYDRA_ADDR" }}"
public = "https://auth.coldwire.org/"

  [[hydra.clients]]
  ClientId = "cw-matrix"
  ClientSecret = "{{ with secret "services/data/cw-oidc-secrets" }}{{ .Data.data.cw_matrix }}{{ end }}"
  GrantTypes = ["authorization_code", "refresh_token"]
  ResponseTypes = ["code", "id_token"]
  Scope = "openid,offline"
  RedirectUris = ["https://matrix.coldwire.org/_synapse/client/oidc/callback"]
  TokenEndpointAuthMethod = "client_secret_post"

  [[hydra.clients]]
  ClientId = "bloc"
  ClientSecret = "{{ with secret "services/data/cw-oidc-secrets" }}{{ .Data.data.cw_bloc }}{{ end }}"
  GrantTypes = ["authorization_code", "refresh_token"]
  ResponseTypes = ["code", "id_token"]
  Scope = "openid,offline"
  RedirectUris = ["https://bloc.coldwire.org/user/auth/oauth2/callback"]
  TokenEndpointAuthMethod = "client_secret_post"