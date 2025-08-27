# Apache Guacamole – Docker Quickstart (Bangla-friendly)

এই প্যাকেজটা দিয়ে আপনি **Docker** এ খুব সহজে Apache Guacamole চালাতে পারবেন। শুধু `scripts/setup.sh` রান করলেই হবে – এটা নিজে থেকেই ডাটাবেস স্কিমা বানাবে, কনটেইনারগুলো তুলবে, আর আপনি `http://SERVER_IP:8080` এ লগইন করতে পারবেন।

**ডিফল্ট লগইন:** `guacadmin / guacadmin` (লগইন করে সাথে সাথে পাসওয়ার্ড চেঞ্জ করুন)।

---

## 1) Requirements
- Docker (এবং Docker Compose plugin)
- ইন্টারনেট (ইমেজ pull করার জন্য)
- Linux server (উবুন্টু 20.04/22.04/24.04 tested)

## 2) ফাইলসমূহ
- `docker-compose.yml` – Guacamole stack (MariaDB + guacd + guacamole)
- `.env` – environment variables (password/port/version ইত্যাদি)
- `mysql-init/001-initdb.sql` – Guacamole DB schema (script স্বয়ংক্রিয়ভাবে তৈরি করবে)
- `scripts/setup.sh` – এক-ক্লিক ইনস্টলার
- `caddy/Caddyfile` – (ঐচ্ছিক) HTTPS reverse proxy

## 3) ইনস্টল/রান (One‑liner)
```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

শেষে দেখবেন:
```
URL:  http://<server-ip>:8080
User: guacadmin
Pass: guacadmin
```

## 4) রিভার্স-প্রক্সি (Caddy সহ SSL) – Optional
`docker-compose.yml` এ **caddy** সার্ভিস অংশটা uncomment করুন এবং `caddy/Caddyfile`-এ আপনার ডোমেইন/ইমেইল বসান। তারপর:
```bash
docker compose up -d caddy
```
Caddy স্বয়ংক্রিয়ভাবে Let's Encrypt থেকে SSL নিয়ে নেবে।

## 5) Backup & Restore
**Backup (DB + configs):**
```bash
docker compose stop guacamole
docker compose exec db sh -c 'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > guacamole-backup.sql
docker compose start guacamole
```

**Restore:**
```bash
docker compose down
docker volume rm $(docker volume ls -q | grep guacamole-docker_db_data) || true
docker compose up -d db
sleep 10
docker exec -i guac_db mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < guacamole-backup.sql
docker compose up -d guacd guacamole
```

## 6) সাধারণ সমস্যা সমাধান
- **লগইন পেজ আসছে না:** `docker compose logs guacamole` দেখুন। DB কানেকশন ঠিক আছে তো?
- **db schema সংক্রান্ত error:** `mysql-init/001-initdb.sql` ফাইলটা তৈরি হয়েছে কি না দেখুন। দরকার হলে ডিলিট করে `./scripts/setup.sh` আবার চালান।
- **পোর্ট ব্যস্ত:** `.env` ফাইলে `GUACAMOLE_PORT` বদলে দিন, যেমন `GUACAMOLE_PORT=8090`।

## 7) নিরাপত্তা
- `.env` এর পাসওয়ার্ডগুলো শক্তিশালী র‍্যান্ডম ভ্যালু। নিজের মতো করে আপডেট করতে পারেন।
- প্রথম লগইনের পর `guacadmin` পাসওয়ার্ড বদলান।
- চাইলে 2FA (TOTP) চালু করতে পারেন — `GUACAMOLE_HOME` এ extension রাখতে হবে।

---

#### ডিফল্ট Admin Panel
```
http://SERVER_IP:8080
User: guacadmin
Pass: guacadmin
```
