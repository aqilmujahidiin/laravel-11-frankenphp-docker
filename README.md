# FrankenPHP and Laravel Octane with Docker + Laravel 11 & Laravel 12

This repo is a docker boilerplate to use for Laravel projects. Containers included in this docker:

1. [Laravel 11 & 12](https://laravel.com/docs/)
2. [FrankenPHP](https://frankenphp.dev/docs/docker/)
3. PostgreSQL
4. Redis
5. Supervisor
6. [Octane](https://laravel.com/docs/octane)
7. Minio for S3
8. MailPit

The purpose of this repo is to run [Laravel 11 & Laravel 12](https://laravel.com/docs/) in a Docker container using [Octane](https://laravel.com/docs/octane) and [FrankenPHP](https://frankenphp.dev/docs/docker/).

## Installation

Use the package manager [git](https://git-scm.com/downloads) to install Docker boilerplate.

```bash
# setup project locally
$ git clone https://github.com/jaygaha/laravel-11-frankenphp-docker.git
# Navigate to project directory:
$ cd laravel-11-frankenphp-docker
```

## Application Setup

Copy the .env.example file to .env:

```bash
# Linux
$ cp .env.example .env
# OR
# Windows
$ copy .env.example .env
```

Edit the `.env` file to configure your application settings. At a minimum, you should set the following variables:

- `APP_NAME`: The name of your application.
- `APP_ENV`: The environment your application is running in (e.g., local, production).
- `APP_KEY`: The application key (will be generated in the next step).
- `APP_DEBUG`: Set to `true` for debugging.
- `APP_URL`: The URL of your application.
- `DB_CONNECTION`: The database connection (e.g., `pgsql`).
- `DB_HOST`: The database host.
- `DB_PORT`: The database port (e.g., `5432` for PostgreSQL).
- `DB_DATABASE`: The database name.
- `DB_USERNAME`: The database username.
- `DB_PASSWORD`: The database password.

**Edit docker related setting according to your preferences.**

Run composer to install the required packages:

```bash
# install required packages
$ composer install
```

Generate a new application key:

```bash
# app key setup
$ php artisan key:generate
```

## Usage

Build the Docker images:

```bash
# build docker images
$ docker compose build
```

Run the containers:

```bash
# Run containers
$ docker compose up -d
```

To stop the containers, run:

```bash
# Stop containers
$ docker compose down
```

To view the logs of a specific container, run:

```bash
# View logs
$ docker compose logs <container_name>
```

**If you are using podman replace `docker` with `podman`**

To access the application, open your browser and navigate to the URL specified in the `APP_URL` variable in your `.env` file.


## Upgrading

Upgrading To 12.0 From 11.x

```bash
$ composer update
```

## Production Deployment

This repository includes a production-ready Docker configuration with security hardening and performance optimizations.

### Quick Start (Production)

On the server you only need **Docker** (Composer / PHP on the host are optional). Dependencies are installed **during the image build**.

```bash
# 1. Create production env file
cp .env.production.example .env.production

# 2. Edit .env.production: DB_*, APP_DOMAIN, OCTANE_HOST, LETSENCRYPT_EMAIL, APP_URL, SESSION_DOMAIN, etc.

# 3. Build and run (postgres + redis + web must be up before artisan below)
docker compose --env-file .env.production -f docker-compose.prod.yml build
docker compose --env-file .env.production -f docker-compose.prod.yml up -d

# 4. Generate APP_KEY inside the web container (writes into mounted .env.production if that file is the container .env)
docker compose --env-file .env.production -f docker-compose.prod.yml exec web php artisan key:generate --force

# 5. Run migrations
docker compose --env-file .env.production -f docker-compose.prod.yml exec web php artisan migrate --force

# 6. Restart web so Octane picks up the new key/config
docker compose --env-file .env.production -f docker-compose.prod.yml restart web

# 7. Check status
docker compose --env-file .env.production -f docker-compose.prod.yml ps
```

### Production Files

| File | Description |
|------|-------------|
| `.docker/php/Dockerfile.prod` | Multi-stage production Dockerfile with FrankenPHP |
| `.docker/php/php.prod.ini` | Hardened PHP configuration with OPcache |
| `.docker/etc/supervisor.d/supervisord.prod.conf` | Production supervisor with Octane + 2 queue workers |
| `docker-compose.prod.yml` | Production compose with resource limits and health checks |
| `.docker/php/Caddyfile.prod` | Octane/Caddy site config (TLS email placeholder filled at container start) |
| `.docker/php/docker-entrypoint-prod.sh` | Injects `LETSENCRYPT_EMAIL` into the Caddyfile, then starts Supervisor |
| `.env.production.example` | Production environment template |
| `.env.production` | Your production environment config (create from example) |
| `.dockerignore` | Excludes dev files from production image |

### Production Setup

1. Copy the production environment file:

```bash
cp .env.production.example .env.production
```

2. Configure production environment variables in `.env.production`, then after containers are running set the app key with Artisan **inside the `web` container**:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml exec web php artisan key:generate --force
```

Required settings:
   - `APP_KEY`: Application encryption key (required)
   - `DB_PASSWORD`: Set a strong database password
   - `APP_URL`: Your production domain (e.g., `https://your-domain.com`)
   - `APP_DOMAIN`: Hostname only (e.g., `your-domain.com`) — must match DNS and `OCTANE_HOST`
   - `LETSENCRYPT_EMAIL`: Email for Let's Encrypt / ACME registration (required)
   - `OCTANE_HOST` / `OCTANE_PORT`: Typically your domain and `443` (FrankenPHP + Caddy HTTPS)
   - `SESSION_DOMAIN`: Your domain for cookies (e.g., `your-domain.com`)
   - Configure mail and S3 credentials as needed

3. Build the production image:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml build
```

4. Run production containers:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml up -d
```

5. Verify all containers are healthy:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml ps
```

### Production Setup (FrankenPHP + Caddy HTTPS)

TLS and HTTP→HTTPS redirection are handled **inside the `web` container** by **FrankenPHP / Octane’s embedded Caddy** (see `.docker/php/Caddyfile.prod` and Supervisor `octane:frankenphp --https --http-redirect`). No separate Nginx or Traefik container is required.

1. Ensure domain and firewall are ready:
   - Point your domain `A` record to the server IP.
   - Open inbound ports `80` and `443` on the host (mapped to the same ports in the `web` container).

2. Set these in `.env.production` (see `.env.production.example`):

```bash
APP_DOMAIN=your-domain.com
LETSENCRYPT_EMAIL=you@example.com
OCTANE_HOST=your-domain.com
OCTANE_PORT=443
OCTANE_HTTPS=true
APP_URL=https://your-domain.com
SESSION_DOMAIN=your-domain.com
```

3. Build and start production:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

4. TLS certificates are stored in the named volume `caddy-data` (mounted at `/data` in the `web` container) so they survive container recreation.

5. Check logs:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml logs -f web
```

6. Verify HTTPS from the server (SNI must match your public hostname — use `--resolve` when calling `https://127.0.0.1`):

```bash
curl -kI --resolve your-domain.com:443:127.0.0.1 https://your-domain.com/up
```

When DNS points to this machine, open `https://your-domain.com` in a browser.

### Apple Silicon / ARM64 Notes

The production configuration includes `platform: linux/amd64` for the web container. This is required because FrankenPHP has compatibility issues on ARM64 architecture that cause segmentation faults. The x86_64 emulation via Rosetta 2 works reliably.

If deploying to an AMD64/x86_64 server, you can optionally remove the `platform` line for native performance.

### Troubleshooting Production

**Container keeps restarting with exit code 139:**
- This is a SIGSEGV (segmentation fault), typically caused by FrankenPHP on ARM64
- Ensure `platform: linux/amd64` is set in docker-compose.prod.yml

**"No application encryption key" error:**
- Ensure `APP_KEY` is set in `.env.production`
- The `.env.production` file must be mounted to the container (configured in docker-compose.prod.yml)

**PostgreSQL fails to start or stays unhealthy:**
- Ensure `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` match what you expect (they map to `POSTGRES_*` in Compose).
- Check logs: `docker compose logs postgres`
- On first boot, an existing non-PostgreSQL data directory on the volume will prevent startup—use a fresh volume path if you switched from MySQL.

**`APP_DOMAIN` / missing env when running Compose:**
- Prefer `docker compose --env-file .env.production ...` so variables used for interpolation are loaded.
- Set `APP_DOMAIN` (hostname only) and `LETSENCRYPT_EMAIL` in `.env.production`; they are required for health checks and ACME email injection into the Caddyfile at container start.

**HTTPS / TLS “wrong host” or `openssl s_client` fails for your domain but works for `127.0.0.1`:**
- Caddy’s site block uses Octane’s `--host`, wired from **`APP_DOMAIN`** in Supervisor (`%(ENV_APP_DOMAIN)s`). If `APP_DOMAIN` is unset or wrong, TLS/SNI may only match `127.0.0.1`.
- Testing locally: `curl` uses SNI from the URL host. Prefer `--resolve` so SNI matches DNS:
  `curl -kI --resolve your-domain.com:443:127.0.0.1 https://your-domain.com/up`

**`/up` returns HTTP 500:**
- Often missing **`APP_KEY`** or database not migrated. Run: `docker compose ... exec web php artisan key:generate --force` and `php artisan migrate --force`, then restart `web`.
- Inspect errors: `docker compose ... exec web tail -n 80 storage/logs/laravel.log` (path inside the container).

**`Bind for 0.0.0.0:80 failed: port is already allocated`:**
- Another service or container is already using host port **80** (often another `docker-proxy`). Stop that stack or change host ports via `APP_HTTP_PORT` / `APP_HTTPS_PORT` in `.env.production`.

**`failed to solve ... database/mysql-database: permission denied`:**
- This usually comes from legacy local folders in build context, not from an active MySQL service.
- Add these paths to `.dockerignore` if you do not use them:
  - `database/mysql-database`
  - `database/mysql-database-test`
  - `database/redis-database`
- Or fix ownership/permissions on those directories in the deploy server.

**Dev dependencies not found during build:**
- The `composer.json` includes a `dont-discover` list for dev-only packages
- Packages like `laravel/sail`, `nunomaduro/collision`, and `spatie/laravel-ignition` are excluded from auto-discovery

### Production Security Features

- **Multi-stage build**: Smaller image without build dependencies
- **Non-root workers**: Queue workers run as `appuser` (UID 1000)
- **No debug tools**: Xdebug and dev dependencies excluded
- **Hardened PHP**: `display_errors=off`, `expose_php=off`
- **OPcache enabled**: JIT compilation for performance
- **FrankenPHP + Octane**: High-performance request handling with 4 workers
- **Resource limits**: CPU and memory constraints prevent runaway processes
- **Health checks**: Container-level health monitoring with `/up` endpoint
- **Secure sessions**: HTTP-only, secure cookies enabled
- **Log rotation**: JSON file logging with size limits
- **Dev packages excluded**: Auto-discovery disabled for dev-only service providers

### Production Checklist

Before deploying to production, ensure:

- [ ] Strong, unique passwords for database and Redis
- [ ] `APP_DEBUG=false` and `APP_ENV=production`
- [ ] `APP_KEY` generated (`docker compose exec web php artisan key:generate --force`)
- [ ] Database migrated (`docker compose exec web php artisan migrate --force`)
- [ ] HTTPS configured (FrankenPHP + Caddy on ports 80/443, or another reverse proxy if you choose not to use embedded Caddy)
- [ ] Secrets managed externally (Docker secrets, Vault, etc.)
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Log aggregation configured (ELK, CloudWatch, etc.)

### Differences: Local vs Production

| Aspect | Local (`Dockerfile.local`) | Production (`Dockerfile.prod`) |
|--------|---------------------------|-------------------------------|
| Base image | `dunglas/frankenphp:1.1-builder-php8.2` | `dunglas/frankenphp:latest-php8.3` |
| Platform | Native | `linux/amd64` (for ARM64 compatibility) |
| Xdebug | Installed | Not included |
| Composer | With dev deps | `--no-dev` |
| display_errors | On | Off |
| OPcache | Disabled | Enabled with JIT |
| User | Root | appuser (1000) for workers |
| Volumes | Source mounted | Image contains code + `.env` mounted + `caddy-data` for TLS storage |
| Reverse proxy / TLS | Dev HTTP (`Dockerfile.local`) | FrankenPHP + Octane Caddy (`--https`) on host ports 80/443 |
| Resource limits | None | CPU/Memory constrained |
| PostgreSQL image | `postgres:16-alpine` | `postgres:16-alpine` |
| Queue workers | 1 worker | 2 workers |

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

FREE TO USE

### Happy Coding :)
