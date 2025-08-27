# Apache Guacamole — Docker Quickstart

Run **Apache Guacamole** on Docker with a single command. The included `scripts/setup.sh` bootstraps the database schema, starts all containers, and prints the login URL.

> **Default login:** `guacadmin / guacadmin` — change this immediately after first login.

---

## 1) Requirements

* Docker + Docker Compose plugin
* Internet connectivity (to pull images)
* Linux server (tested on Ubuntu 20.04/22.04/24.04)

---

## 2) Repository Layout

* `docker-compose.yml` — Guacamole stack (MariaDB + `guacd` + Guacamole web)
* `.env` — environment variables (ports, versions, passwords)
* `mysql-init/001-initdb.sql` — Guacamole DB schema (created by the setup script)
* `scripts/setup.sh` — one-click installer
* `caddy/Caddyfile` — *(optional)* HTTPS reverse proxy (automatic SSL)

---

## 3) Quick Start (one command)

```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

When it finishes, you’ll see something like:

```
URL:  http://<SERVER_IP>:8080
User: guacadmin
Pass: guacadmin
```

---

## 4) Configure (optional)

Edit `.env` to match your needs. Example:

```env
# Web
GUACAMOLE_PORT=8080
TZ=UTC

# Versions (set to "latest" or pin specific tags)
GUACAMOLE_IMAGE=guacamole/guacamole:latest
GUACD_IMAGE=guacamole/guacd:latest
MARIADB_IMAGE=mariadb:11

# Database
MYSQL_DATABASE=guacamole_db
MYSQL_USER=guacamole
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me_root
```

> Any time you change `.env`, run `docker compose up -d` to apply (or restart the relevant services).

---

## 5) Reverse Proxy with HTTPS (Caddy) — optional

If you want HTTPS with automatic Let’s Encrypt:

1. In `docker-compose.yml`, **uncomment** the `caddy` service block.
2. Edit `caddy/Caddyfile`:

   ```caddy
   guac.example.com {
     reverse_proxy guacamole:8080
     encode gzip
   }
   ```
3. Bring it up:

   ```bash
   docker compose up -d caddy
   ```

Visit `https://guac.example.com`.

---

## 6) Backup & Restore

### Backup (DB + configs)

```bash
# Stop the web app to ensure a consistent dump
docker compose stop guacamole

# Dump the database to a local file
docker compose exec db sh -c 'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > guacamole-backup.sql

# Start the web app again
docker compose start guacamole
```

### Restore

```bash
# Stop everything and remove the DB volume so we start clean
docker compose down
docker volume rm $(docker volume ls -q | grep guacamole-docker_db_data) || true

# Bring DB up first and wait a bit
docker compose up -d db
sleep 10

# Restore the SQL dump into the fresh database
docker exec -i guac_db mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < guacamole-backup.sql

# Start the rest of the stack
docker compose up -d guacd guacamole
```

---

## 7) Troubleshooting

* **Blank/404 login page**
  Check logs:

  ```bash
  docker compose logs -f guacamole
  docker compose logs -f db
  ```

  Make sure Guacamole can connect to the DB (env values correct, DB started first).

* **Schema/initialization errors**
  The init script creates `mysql-init/001-initdb.sql`. If you see schema errors, remove it and rerun:

  ```bash
  rm -f mysql-init/001-initdb.sql
  ./scripts/setup.sh
  ```

* **Port already in use**
  Change `GUACAMOLE_PORT` in `.env` (e.g., `8090`) and:

  ```bash
  docker compose up -d
  ```

* **Slow first start**
  The DB may take several seconds to accept connections. The setup script waits, but on very slow disks you might need to `docker compose restart guacamole` once the DB is ready.

---

## 8) Security Notes

* Change the default `guacadmin` password after first login.
* Use strong, unique values in `.env` (especially `MYSQL_*` variables).
* Keep the repo private if you store secrets. Prefer committing `.env.example` and inject real secrets via your deployment environment or Docker secrets.
* Consider enabling 2FA (TOTP) via Guacamole extensions.

---

## 9) Useful Commands

```bash
# Start / stop / view
docker compose up -d
docker compose ps
docker compose logs -f guacamole

# Restart a single service
docker compose restart guacamole

# Update images
docker compose pull
docker compose up -d

# Tear down
docker compose down
```

---

## 10) Access

* **Default URL:** `http://SERVER_IP:8080`
* **Default credentials:** `guacadmin / guacadmin` (change immediately)

---

### Credits

* [Apache Guacamole](https://guacamole.apache.org/)
* Official Docker images: `guacamole/guacamole`, `guacamole/guacd`, `mariadb`
