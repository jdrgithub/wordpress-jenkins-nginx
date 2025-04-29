#!/bin/sh

# Set NGINX_ENV=dev or NGINX_ENV=prod in docker-compose.yml

# Pick correct nginx.conf based on environment
if [ "$NGINX_ENV" = "dev" ]; then
    TEMPLATE_CONF=/etc/nginx/nginx.dev.conf
else
    TEMPLATE_CONF=/etc/nginx/nginx.prod.conf
fi

# Substitute environment variables and start nginx
envsubst '$TRUSTED_LAN $HOST_LAN_IP' < $TEMPLATE_CONF > /etc/nginx/nginx.conf
nginx -c /etc/nginx/nginx.conf -g 'daemon off;'


echo "🔁 Waiting for wordpress to resolve..."

until getent hosts wordpress > /dev/null; do
  echo "⏳ wordpress not yet resolvable..."
  sleep 2
done

echo "✅ wordpress resolved! Starting nginx..."
exec nginx -g "daemon off;"

