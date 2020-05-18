#!/bin/bash
set -e

echo "Fetching Nomad... ${NOMAD_VERSION}"
cd /tmp
curl -L -o nomad.zip "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_arm.zip"

echo "Installing Nomad..."
unzip nomad.zip >/dev/null
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

echo "Nomad installation finished."