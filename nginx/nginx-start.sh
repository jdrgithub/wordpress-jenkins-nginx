#!/bin/sh




# Set NGINX_ENV=dev or NGINX_ENV=prod in docker-compose.yml

# Pick correct nginx.conf based on environment
if [ "$NGINX_ENV" = "dev" ]; then
    TEMPLATE_CONF=/etc/nginx/nginx.dev.conf
else
    TEMPLATE_CONF=/etc/nginx/nginx.prod.conf
fi

# Substitute environment variables and start nginx
echo "🔍 Template source:"
cat $TEMPLATE_CONF | grep local_lan_ip || echo "✅ No 'local_lan_ip' in template"

echo "🔍 Environment before envsubst:"
env | grep -i lan



envsubst '$HOST_LAN_IP' < $TEMPLATE_CONF > /etc/nginx/nginx.conf

echo "🔍 Showing final /etc/nginx/nginx.conf"
cat /etc/nginx/nginx.conf

echo "🔍 Listing everything in /etc/nginx"
ls -l /etc/nginx
exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'


echo "🔁 Waiting for wordpress to resolve..."

until getent hosts wordpress > /dev/null; do
  echo "⏳ wordpress not yet resolvable..."
  sleep 2
done

echo "✅ wordpress resolved! Starting nginx..."
exec nginx -g "daemon off;"

