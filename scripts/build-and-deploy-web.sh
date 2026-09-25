#!/usr/bin/env bash
set -e

# ==============================================================================
# Script: build-and-deploy-web.sh
# Purpose: Build and deploy Luna Mobile Flutter Web to /var/www/luna-web
# Usage:
#   ./build-and-deploy-web.sh               # Full build & deploy
#   ./build-and-deploy-web.sh --build-only  # Only compile web release
#   ./build-and-deploy-web.sh --deploy-only # Only copy build/web to /var/www
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../apps/luna_mobile" && pwd)"
BUILD_DIR="$APP_DIR/build/web"
WEB_ROOT="/var/www/luna-web"
DOMAIN="luna.nexacode.dev"

export PATH="$PATH:/opt/flutter/bin"
export CI=true

MODE="all"
if [ "$1" = "--build-only" ]; then
    MODE="build"
elif [ "$1" = "--deploy-only" ]; then
    MODE="deploy"
fi

# 1. Build Phase
if [ "$MODE" = "all" ] || [ "$MODE" = "build" ]; then
    if ! command -v flutter >/dev/null 2>&1; then
        echo "Error: Flutter SDK not found in PATH or /opt/flutter/bin!"
        exit 1
    fi

    echo "==> [1/3] Fetching dependencies for Luna Mobile..."
    (cd "$APP_DIR" && flutter pub get)

    echo "==> [2/3] Building Flutter Web (release, host: $DOMAIN)..."
    (cd "$APP_DIR" && flutter build web --release --dart-define="HOST=$DOMAIN")

    echo "==> Build successful: $BUILD_DIR"
fi

# 2. Deploy Phase
if [ "$MODE" = "all" ] || [ "$MODE" = "deploy" ]; then
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Error: Build directory $BUILD_DIR does not exist. Run with --build-only first."
        exit 1
    fi

    echo "==> [3/3] Deploying to $WEB_ROOT..."
    mkdir -p "$WEB_ROOT"
    rm -rf "${WEB_ROOT:?}"/*
    cp -r "$BUILD_DIR"/* "$WEB_ROOT/"

    chown -R www-data:www-data "$WEB_ROOT"
    chmod -R 755 "$WEB_ROOT"

    echo "==> Reloading Nginx..."
    systemctl reload nginx

    echo "==> Validating deployment..."
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/")
    HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health")

    echo "    - Web Root (https://$DOMAIN/): HTTP $STATUS_CODE"
    echo "    - Backend (https://$DOMAIN/health): HTTP $HEALTH_CODE"

    if [ "$STATUS_CODE" = "200" ] && [ "$HEALTH_CODE" = "200" ]; then
        echo "==> Deployment completed successfully!"
    else
        echo "==> Warning: One or more endpoints returned non-200 status code."
    fi
fi
