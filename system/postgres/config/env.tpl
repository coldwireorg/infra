PG_SU_PWD={{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_su_password }}{{ end }}
PG_REPL_PWD={{ with secret "system/data/cw-stolon" }}{{ .Data.data.psql_repl_password }}{{ end }}
