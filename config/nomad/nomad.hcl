data_dir  = "/opt/nomad/data"
plugin_dir = "/opt/nomad/plugins"

bind_addr = "0.0.0.0" # the default

advertise {
  http = "127.0.0.1"
  rpc  = "127.0.0.1"
  serf = "127.0.0.1" # non-default ports may be specified
}

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"
}

