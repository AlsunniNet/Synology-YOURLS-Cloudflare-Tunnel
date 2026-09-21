#!/bin/bash

# Clear screen for clean output
clear

echo "=================================================="
echo "   YOURLS & Cloudflare Tunnel Setup for Synology  "
echo "=================================================="
echo ""

# Interactive Variable Collection
read -p "Enter Project Directory [/volume1/docker/yourls-qr-asfec-sa]: " PROJECT_DIR
PROJECT_DIR=${PROJECT_DIR:-"/volume1/docker/yourls-qr-asfec-sa"}

read -p "Enter Database Root Password [Asfec2024]: " MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"Asfec2024"}

read -p "Enter Database Name [yourls]: " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-"yourls"}

read -p "Enter Database User [yourls]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-"yourls"}

read -p "Enter Database Password [Alsunni2010]: " MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"Alsunni2010"}

read -p "Enter YOURLS Admin Username [laith]: " YOURLS_USER
YOURLS_USER=${YOURLS_USER:-"laith"}

read -p "Enter YOURLS Admin Password [Alsunni2010]: " YOURLS_PASS
YOURLS_PASS=${YOURLS_PASS:-"Alsunni2010"}

read -p "Enter YOURLS Domain (with https://) [https://qr.asfec.sa]: " YOURLS_SITE
YOURLS_SITE=${YOURLS_SITE:-"https://qr.asfec.sa"}

read -p "Enter Cloudflare Tunnel Token: " TUNNEL_TOKEN

# Validate required Cloudflare Tunnel Token input
if [ -z "$TUNNEL_TOKEN" ]; then
  echo -e "\nError: Cloudflare Tunnel Token is required. Exiting..."
  exit 1
fi

# Define directory structures
MARIADB_DIR="$PROJECT_DIR/mariadb"
HTML_DIR="$PROJECT_DIR/html-user"

echo -e "\n--> Creating project directories at $PROJECT_DIR..."
mkdir -p "$MARIADB_DIR" "$HTML_DIR"

# Set correct ownership for MariaDB (UID/GID 999 is standard for official MariaDB/MySQL containers)
echo "--> Fixing directory permissions for MariaDB and YOURLS..."
chown -R 999:999 "$MARIADB_DIR"
chmod -R 755 "$PROJECT_DIR"

echo "--> Generating docker-compose.yml..."
cat << EOF > "$PROJECT_DIR/docker-compose.yml"
version: '3.8'

services:
  db:
    image: mariadb:11.4-noble
    container_name: db-qr-asfec-sa
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - ${MARIADB_DIR}:/var/lib/mysql
    networks:
      - network-qr-asfec-sa

  yourls:
    image: yourls:latest
    container_name: web-qr-asfec-sa
    restart: always
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      - YOURLS_SITE=${YOURLS_SITE}
      - YOURLS_USER=${YOURLS_USER}
      - YOURLS_PASS=${YOURLS_PASS}
      - YOURLS_DB_HOST=db-qr-asfec-sa
      - YOURLS_DB_USER=${MYSQL_USER}
      - YOURLS_DB_PASS=${MYSQL_PASSWORD}
      - YOURLS_DB_NAME=${MYSQL_DATABASE}
    volumes:
      - ${HTML_DIR}:/var/www/html/user
    networks:
      - network-qr-asfec-sa

  tunnel:
    image: cloudflare/cloudflared:latest
    container_name: tunnel-qr-asfec-sa
    restart: always
    command: tunnel --no-autoupdate run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    networks:
      - network-qr-asfec-sa
    depends_on:
      - yourls

networks:
  network-qr-asfec-sa:
    driver: bridge
EOF

echo "--> Starting containers..."
cd "$PROJECT_DIR"
docker compose up -d

echo ""
echo "=================================================="
echo " Deployment completed successfully!"
echo " Access YOURLS via Cloudflare: ${YOURLS_SITE}"
echo "=================================================="
