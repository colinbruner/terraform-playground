#!/bin/bash -e

###
# Install Nomad
###

sudo apt-get install -y nomad

# Validate Nomad was installed successfully
nomad version &> /dev/null
if [[ $? == 0 ]]; then
    echo "Nomad was installed successfully."
else
    echo "ERROR: Nomad installation failed, Error Code: $?"
	exit 1
fi

# https://learn.hashicorp.com/tutorials/nomad/production-deployment-guide-vm-with-consul#configure-systemd
sudo tee /etc/systemd/system/nomad.service << EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
#Wants=consul.service
#After=consul.service

[Service]
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2

## Configure unit start rate limiting. Units which are started more than
## *burst* times within an *interval* time span are not permitted to start any
## more. Use 'StartLimitIntervalSec' or 'StartLimitInterval' (depending on
## systemd version) to configure the checking interval and 'StartLimitBurst'
## to configure how many starts per interval are allowed. The values in the
## commented lines are defaults.

# StartLimitBurst = 5

## StartLimitIntervalSec is used for systemd versions >= 230
# StartLimitIntervalSec = 10s

## StartLimitInterval is used for systemd versions < 230
# StartLimitInterval = 10s

TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF

# Enable so process starts on next boot
sudo systemctl enable nomad