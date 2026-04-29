#!/bin/sh
set -e

CADDY_FILE="/var/www/html/.docker/php/Caddyfile.prod"
EMAIL="${LETSENCRYPT_EMAIL:-}"

if [ -z "$EMAIL" ]; then
	echo "docker-entrypoint-prod: WARN: LETSENCRYPT_EMAIL is empty; set it in .env.production for Let's Encrypt."
	EMAIL="invalid@example.com"
fi

if [ -f "$CADDY_FILE" ]; then
	sed -i "s|__LETSENCRYPT_EMAIL__|${EMAIL}|g" "$CADDY_FILE"
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
