#!/bin/sh

echo "🔁 Waiting for wordpress to resolve..."

until getent hosts wordpress > /dev/null; do
  echo "⏳ wordpress not yet resolvable..."
  sleep 2
done

echo "✅ wordpress resolved! Starting nginx..."
exec nginx -g "daemon off;"

