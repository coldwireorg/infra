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
  password = "{{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_su_password }}{{ end }}"
  name = "cw_auth"

[hydra]
proxy = "false"
admin = "http://{{ env "HYDRA_ADDR" }}"
public = "https://auth.coldwire.org/"