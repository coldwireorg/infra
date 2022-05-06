datacenter  = "coldnet"
data_dir    = "/opt/consul"
bind_addr   = "{{ GetInterfaceIP \"coldnet\" }}"
client_addr = "{{ GetInterfaceIP \"coldnet\" }}"
retry_join  = ["10.42.0.1"]