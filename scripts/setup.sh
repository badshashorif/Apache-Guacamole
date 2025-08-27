#!/usr/bin/env bash
set -euo pipefail

echo "[*] Apache Guacamole Docker quick installer"
echo "[*] This script will:"
echo "    1) Generate the DB schema SQL"
echo "    2) Start MariaDB, guacd and Guacamole"
echo ""

# Check dependencies
command -v docker >/dev/null 2>&1 || { echo "[X] docker not found. Install Docker first."; exit 1; }
if ! docker compose version >/dev/null 2>&1; then
  if ! docker-compose --version >/dev/null 2>&1; then
    echo "[X] docker compose plugin not found. Install Docker Compose."
    exit 1
  else
    COMPOSE_BIN="docker-compose"
  fi
else
  COMPOSE_BIN="docker compose"
fi

# Load .env
if [[ ! -f ".env" ]]; then
  echo "[*] .env not found. Creating from defaults..."
  cp .env .env.bak 2>/dev/null || true
fi
set -o allexport
source .env
set +o allexport

GUAC_VERSION="${GUAC_VERSION:-1.5.5}"

# Prepare init SQL
mkdir -p mysql-init
if [[ ! -f "mysql-init/001-initdb.sql" ]]; then
  echo "[*] Generating Guacamole DB schema (version ${GUAC_VERSION})..."
  docker run --rm guacamole/guacamole:${GUAC_VERSION} /opt/guacamole/bin/initdb.sh --mysql > mysql-init/001-initdb.sql
  echo "[*] Wrote mysql-init/001-initdb.sql"
else
  echo "[*] mysql-init/001-initdb.sql already exists. Skipping generation."
fi

# Pull images
$COMPOSE_BIN pull

# Start DB first
echo "[*] Starting MariaDB..."
$COMPOSE_BIN up -d db

echo "[*] Waiting for DB to become ready..."
for i in {1..60}; do
  if docker exec guac_db mysqladmin ping --silent -p"${MYSQL_ROOT_PASSWORD}" >/dev/null 2>&1; then
    echo "[*] DB is up."
    break
  fi
  sleep 2
done

# Start the rest
echo "[*] Starting guacd and guacamole..."
$COMPOSE_BIN up -d guacd guacamole

echo ""
echo "[✓] Done!"
echo "URL:  http://$(hostname -I | awk '{print $1}'):${GUACAMOLE_PORT}"
echo "User: guacadmin"
echo "Pass: guacadmin"
echo ""
echo ">> IMPORTANT: Immediately log in and change the default password."
