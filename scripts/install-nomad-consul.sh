#/bin/bash

ARCH=$1
NOMAD_VERSION=$2
CONSUL_VERSION=$3
REGION=$4

if [ $# -lt 4 ]
then
  echo "usage: ./script.sh <architecture (arm64/amd64)> <version of nomad (1.2.6)> <version of consul (1.12.0)> <region/type of server (storage or node)>"
fi

# binaries
NOMAD_URL="https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${ARCH}.zip"
CONSUL_URL="https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${ARCH}.zip"

# configuration files
NOMAD_CONF="https://codeberg.org/coldwire/infra/raw/branch/main/config/nomad/nomad-client.hcl"
NOMAD_SERVICE="https://codeberg.org/coldwire/infra/raw/branch/main/config/nomad/nomad.service"
CONSUL_CONF="https://codeberg.org/coldwire/infra/raw/branch/main/config/consul/consul-client.hcl"
CONSUL_SERVICE="https://codeberg.org/coldwire/infra/raw/branch/main/config/consul/consul.service"

NOMAD_DIR="/etc/nomad.d"
CONSUL_DIR="/etc/consul.d"

# create nomad related dir
mkdir ${NOMAD_DIR}
mkdir /opt/nomad
mkdir /opt/plugins

# create consul related dir
mkdir ${CONSUL_DIR}
mkdir /opt/consul

# download config
wget ${NOMAD_CONF} -P ${NOMAD_DIR} -O nomad.hcl
wget ${CONSUL_CONF} -P ${CONSUL_DIR} -O consul.hcl
sed -i 'region = "${REGION}"' ${NOMAD_DIR}/nomad.hcl # add region to nomad

# download service files
wget ${NOMAD_SERVICE} -P /etc/systemd/system/
wget ${CONSUL_SERVICE} -P /etc/systemd/system/

# download bin
wget -O nomad.zip ${NOMAD_URL} && unzip nomad.zip && chmod +x nomad && mv nomad /usr/local/bin/
wget -O consul.zip ${CONSUL_URL} && unzip consul.zip && chmod +x consul && mv consul /usr/local/bin/

systemctl enable --now nomad consul