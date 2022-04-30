metadata_dir = "/meta"
data_dir = "/data"

replication_mode = "2"

compression_level = 2

rpc_bind_addr = "0.0.0.0:3901"
rpc_public_addr = "{{ env "SRV_IP" }}:3901"
rpc_secret = "{{ with secret "services/data/cw-storage" }}{{ .Data.data.garage_rpc_secret }}{{ end }}"

bootstrap_peers = []

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage"