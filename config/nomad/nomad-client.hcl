datacenter = "coldnet"

data_dir   = "/opt/nomad"
plugin_dir = "/opt/plugins"

addresses {
  http = "{{ GetInterfaceIP \"coldnet\" }}"
  rpc  = "{{ GetInterfaceIP \"coldnet\" }}"
  serf = "{{ GetInterfaceIP \"coldnet\" }}"
}

advertise {
  http = "{{ GetInterfaceIP \"coldnet\" }}"
  rpc  = "{{ GetInterfaceIP \"coldnet\" }}"
  serf = "{{ GetInterfaceIP \"coldnet\" }}"
}

client {
  enabled = true
  network_interface = "coldnet"
  server_join {
    retry_join = ["10.42.0.1"]
  }
}

consul {
  address = "{{ GetInterfaceIP \"coldnet\" }}:8500"
}

vault {
  enabled = true
  address = "http://10.42.0.1:8200"
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
