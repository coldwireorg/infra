datacenter = "coldnet"

data_dir = "/opt/consul"

client_addr = "{{ GetInterfaceIP \"coldnet\" }}"

ui_config{
  enabled = true
}

server = true

bootstrap_expect = 1