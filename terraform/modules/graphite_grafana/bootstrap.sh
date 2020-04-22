#!/bin/bash

sleep 30

snap install docker
systemctl enable snap.docker.dockerd
systemctl start snap.docker.dockerd

sleep 30

docker run -d \
    --name graphite \
    --restart=always \
    -p 80:80 \
    -p 2003-2004:2003-2004 \
    -p 2023-2024:2023-2024 \
    -p 8125:8125/udp \
    -p 8126:8126 \
    graphiteapp/graphite-statsd

docker run -d \
    --name grafana \
    --restart=always \
    -p 3000:3000 \
    -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,btplc-trend-box-panel,michaeldmoore-multistat-panel,vonage-status-panel,grafana-piechart-panel,briangann-datatable-panel,mtanda-histogram-panel" \
    grafana/grafana
