#!/bin/bash

# Configuration
SYSTEMD_UNIT="$HOME/.config/systemd/user/make_proxy.service"
CURR_DIR=${PWD}  


# Step 1: Review Environment vars file.
printf "\nReview the ./.env file :\n\n"
cat $CURR_DIR/.env

printf "\nProceed to write systemd unit at $SYSTEMD_UNIT (y/n)? "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo Yes
else
    exit 0
fi

# Step 2: Write systemd unit
echo "[+] Writing systemd user unit..."
cat > "$SYSTEMD_UNIT" <<EOF
[Unit]
Description=make_proxy Client or Server
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=$CURR_DIR/.env
WorkingDirectory=$CURR_DIR
ExecStart=$CURR_DIR/_build/prod/rel/make_proxy/bin/make_proxy start
ExecStop=$CURR_DIR/_build/prod/rel/make_proxy/bin/make_proxy stop
Restart=on-failure
LimitNOFILE=65535
RestartSec=10

[Install]
WantedBy=default.target
EOF


# Step 3: Reload and start service
echo "[+] Enabling and starting make_proxy via systemd..."
systemctl --user daemon-reexec
systemctl --user daemon-reload
systemctl --user enable --now make_proxy.service

echo "[✓] Done."
