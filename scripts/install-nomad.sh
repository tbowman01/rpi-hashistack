#!/bin/bash
set -e

ARCH=$(uname -m)
case $ARCH in
    amd64)
        SUFFIX=amd64
        ;;
    x86_64)
        SUFFIX=amd64
        ;;
    arm64)
        SUFFIX=arm64
        ;;
    aarch64)
        SUFFIX=arm64
        ;;
    arm*)
        SUFFIX=arm
        ;;
    *)
        echo "Unsupported architecture $ARCH"
        exit 1
esac

echo "Fetching Nomad... ${NOMAD_VERSION}"
mkdir /tmp/nomad
pushd /tmp/nomad

curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${SUFFIX}.zip
curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig

# Verify the signature file is untampered.
gpg --homedir /tmp/keyring --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS

# Verify the SHASUM matches the archive.
shasum -a 256 -c nomad_${NOMAD_VERSION}_SHA256SUMS --ignore-missing

echo "Installing Nomad..."
unzip nomad_${NOMAD_VERSION}_linux_${SUFFIX}.zip >/dev/null
mv nomad /usr/local/bin/

mkdir --parents /opt/nomad
mkdir --parents /etc/nomad.d
chmod 700 /etc/nomad.d

cat - > /etc/nomad.d/nomad.hcl <<'EOF'
bind_addr = "0.0.0.0"
data_dir  = "/opt/nomad"

server {
  enabled          = true
  bootstrap_expect = 1
}
client {
  enabled = true
}
EOF

chmod 640 /etc/nomad.d/nomad.hcl

echo "Installing Nomad as a Service..."
cat - > /etc/systemd/system/nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
chmod 0600 /etc/systemd/system/nomad.service

systemctl enable nomad.service

popd
rm -rf /tmp/nomad

echo "Nomad installation finished."