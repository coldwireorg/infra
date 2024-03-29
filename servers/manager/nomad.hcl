data_dir  = "/opt/nomad/data"

datacenter = "coldnet"

#bind_addr = "{{ GetInterfaceIP \"coldnet\" }}" # the default

advertise {
  http = "0.0.0.0"
  rpc  = "{{ GetInterfaceIP \"coldnet\" }}"
  serf = "{{ GetInterfaceIP \"coldnet\" }}"
}


server {
  enabled = true
  bootstrap_expect = 1
}

consul {
  address = "{{ GetInterfaceIP \"coldnet\" }}:8500"
}

vault {
  enabled = true
  address = "http://10.42.0.1:8200"
  task_token_ttl = "72h"
  create_from_role = "nomad-cluster"
}
