#!/usr/bin/env bash
set -e

ARCHIVE_PATH="${1:-/opt/luna_ai/apps/luna_mobile/web.tar.gz}"
WEB_ROOT="/var/www/luna-web"

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "Error: Archive file not found at $ARCHIVE_PATH"
    exit 1
fi

echo "Deploying Flutter Web from $ARCHIVE_PATH to $WEB_ROOT..."
mkdir -p "$WEB_ROOT"
rm -rf "${WEB_ROOT:?}"/*

# Check if archive contains a top-level directory (web/ or build/web/)
if tar -ztf "$ARCHIVE_PATH" | grep -qE "^(web|build/web)/"; then
    tar -zxf "$ARCHIVE_PATH" --strip-components=1 -C "$WEB_ROOT"
else
    tar -zxf "$ARCHIVE_PATH" -C "$WEB_ROOT"
fi

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
systemctl reload nginx

echo "Deployment successful! Check https://luna.nexacode.dev"
