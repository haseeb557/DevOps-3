#!/bin/bash

# Install dependencies
sudo yum update -y
sudo amazon-linux-extras enable nginx1
sudo yum install -y nginx nodejs

# Configure Nginx
cat <<EOF | sudo tee /etc/nginx/conf.d/payment-api.conf
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
EOF
sudo systemctl enable nginx
sudo systemctl start nginx

# Deploy Node.js API
mkdir -p /opt/payment-api
cat <<EOF | sudo tee /opt/payment-api/server.js
const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ "status": "Payment Processed", "timestamp": new Date().toISOString() }));
});

server.listen(3000, () => console.log('Payment API running on port 3000'));
EOF

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/payment-api.service
[Unit]
Description=Payment API Service
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/payment-api/server.js
Restart=always
User=nobody
Group=nobody

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable payment-api
sudo systemctl start payment-api
