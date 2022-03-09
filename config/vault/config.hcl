ui = true

# Storage driver
storage "consul" {
  address = "10.42.0.1:8500"
  path    = "vault"
}

# HTTP listener
listener "tcp" {
  address = "10.42.0.1:8200"
  tls_disable = 1
}
