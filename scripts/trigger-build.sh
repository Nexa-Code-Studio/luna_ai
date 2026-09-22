#!/usr/bin/env bash
# ==============================================================================
# Script Pemicu GitHub Actions Build Mobile (Android APK & iOS Unsigned)
# Repositori: Nexa-Code-Studio/luna_ai
# ==============================================================================

set -e

# Warna terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Direktori proyek root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Nilai default
TARGET="all"
CONFIG="release"
MODE="auto"
DRY_RUN=false
BRANCH="$(git -C "$ROOT_DIR" branch --show-current 2>/dev/null || echo "test")"
REPO_DEFAULT="Nexa-Code-Studio/luna_ai"

# Deteksi nama repository dari remote origin
get_repo_slug() {
  local remote_url
  remote_url="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo "$REPO_DEFAULT"
  fi
}

REPO_SLUG="$(get_repo_slug)"

# Fungsi bantuan
show_help() {
  cat << EOF
Penggunaan:
  $(basename "$0") [OPTIONS]

Deskripsi:
  Memicu workflow GitHub Actions untuk build Android APK dan iPhone iOS (.ipa)
  pada repositori ${REPO_SLUG}.

Opsi:
  -t, --target <all|android|ios|iphone>  Target platform yang akan di-build (default: all)
  -c, --config <release|debug>          Konfigurasi build (default: release)
  -b, --branch <nama_branch>            Branch referensi pemicu (default: current branch '$BRANCH')
  -m, --mode <auto|api|tag>             Metode pemicu (default: auto)
                                        - auto: Pilih API jika token ada, atau Git Tag jika tidak ada
                                        - api : Pakai GitHub REST API / gh CLI (memerlukan GITHUB_TOKEN)
                                        - tag : Buat dan push tag git 'build-*' (menggunakan kredensial Git/SSH)
  -d, --dry-run                         Tampilkan aksi yang akan dijalankan tanpa mengeksekusinya
  -h, --help                            Tampilkan pesan bantuan ini

Contoh:
  # Build Android APK release via pemicu otomatis
  ./scripts/trigger-build.sh --target android

  # Build iPhone (.ipa installer package)
  ./scripts/trigger-build.sh --target iphone

  # Build keduanya (all) dengan dry-run untuk simulasi
  ./scripts/trigger-build.sh --target all --dry-run

  # Paksa menggunakan metode git tag
  ./scripts/trigger-build.sh --target android --mode tag
EOF
}

# Parsing argumen
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      TARGET="$2"
      shift 2
      ;;
    -c|--config)
      CONFIG="$2"
      shift 2
      ;;
    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift 1
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Opsi tidak dikenal '$1'${NC}" >&2
      show_help
      exit 1
      ;;
  esac
done

# Normalisasi alias iphone -> ios
if [[ "$TARGET" == "iphone" ]]; then
  TARGET="ios"
fi

# Validasi target dan config
if [[ "$TARGET" != "all" && "$TARGET" != "android" && "$TARGET" != "ios" ]]; then
  echo -e "${RED}Error: Target tidak valid '$TARGET'. Pilihan: all, android, ios (atau iphone)${NC}" >&2
  exit 1
fi

if [[ "$CONFIG" != "release" && "$CONFIG" != "debug" ]]; then
  echo -e "${RED}Error: Config tidak valid '$CONFIG'. Pilihan: release, debug${NC}" >&2
  exit 1
fi

# Membaca token dari environment atau .env jika ada
load_token() {
  local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -z "$token" && -f "$ROOT_DIR/.env" ]]; then
    token="$(grep -E '^(GITHUB_TOKEN|GH_TOKEN)=' "$ROOT_DIR/.env" | head -n 1 | cut -d '=' -f2- | tr -d '"' | tr -d "'" || true)"
  fi
  echo "$token"
}

TOKEN="$(load_token)"

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   LUNA AI - Mobile Build Workflow Trigger            ${NC}"
echo -e "${CYAN}======================================================${NC}"
echo -e "Repositori : ${GREEN}${REPO_SLUG}${NC}"
echo -e "Branch     : ${GREEN}${BRANCH}${NC}"
echo -e "Target     : ${YELLOW}${TARGET}${NC}"
echo -e "Config     : ${YELLOW}${CONFIG}${NC}"
echo -e "Mode       : ${BLUE}${MODE}${NC}"
echo -e "Dry Run    : $( $DRY_RUN && echo -e "${YELLOW}Aktif (Simulasi)${NC}" || echo -e "${GREEN}Tidak (Live Execution)${NC}" )"
echo ""

# Tentukan metode eksekusi
EXEC_MODE="$MODE"
if [[ "$MODE" == "auto" ]]; then
  if command -v gh >/dev/null 2>&1; then
    EXEC_MODE="gh"
  elif [[ -n "$TOKEN" ]]; then
    EXEC_MODE="api"
  else
    EXEC_MODE="tag"
  fi
fi

# Eksekusi berdasarkan mode
if [[ "$EXEC_MODE" == "gh" ]]; then
  echo -e "${BLUE}ℹ Menggunakan GitHub CLI (gh)...${NC}"
  CMD="gh workflow run build-mobile.yml --repo \"${REPO_SLUG}\" --ref \"${BRANCH}\" -f target=\"${TARGET}\" -f build_type=\"${CONFIG}\""
  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY-RUN] Perintah yang akan dieksekusi:${NC}"
    echo "  $CMD"
  else
    eval "$CMD"
    echo -e "${GREEN}✓ Workflow berhasil dipicu via GitHub CLI!${NC}"
  fi

elif [[ "$EXEC_MODE" == "api" ]]; then
  echo -e "${BLUE}ℹ Menggunakan GitHub REST API (curl)...${NC}"
  if [[ -z "$TOKEN" ]]; then
    echo -e "${RED}Error: GITHUB_TOKEN tidak ditemukan di environment atau file .env!${NC}"
    echo -e "${YELLOW}Tips: Tambahkan GITHUB_TOKEN=ghp_xxx di .env, atau jalankan dengan '--mode tag' untuk trigger tanpa token.${NC}"
    exit 1
  fi

  API_URL="https://api.github.com/repos/${REPO_SLUG}/actions/workflows/build-mobile.yml/dispatches"
  PAYLOAD="{\"ref\": \"${BRANCH}\", \"inputs\": {\"target\": \"${TARGET}\", \"build_type\": \"${CONFIG}\"}}"

  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY-RUN] Request REST API:${NC}"
    echo "  Endpoint: $API_URL"
    echo "  Payload : $PAYLOAD"
    echo "  Header  : Authorization: Bearer [REDACTED]"
  else
    HTTP_CODE=$(curl -s -o /tmp/luna_gh_dispatch.log -w "%{http_code}" \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${API_URL}" \
      -d "${PAYLOAD}")

    if [[ "$HTTP_CODE" == "204" ]]; then
      echo -e "${GREEN}✓ Workflow dispatch berhasil dikirim ke GitHub Actions (HTTP 204)!${NC}"
    else
      echo -e "${RED}✗ Gagal memicu workflow (HTTP ${HTTP_CODE})!${NC}"
      cat /tmp/luna_gh_dispatch.log
      echo ""
      exit 1
    fi
  fi

elif [[ "$EXEC_MODE" == "tag" ]]; then
  TIMESTAMP="$(date +%Y%m%d%H%M%S)"
  TAG_NAME="build-${TARGET}-${CONFIG}-${TIMESTAMP}"
  echo -e "${BLUE}ℹ Menggunakan metode Git Tag Push (tidak memerlukan token API)...${NC}"
  echo -e "Tag yang dibuat : ${YELLOW}${TAG_NAME}${NC}"

  if $DRY_RUN; then
    echo -e "${YELLOW}[DRY-RUN] Perintah git yang akan dieksekusi:${NC}"
    echo "  git -C \"$ROOT_DIR\" tag -a \"$TAG_NAME\" -m \"Trigger mobile build: target=${TARGET}, config=${CONFIG}\""
    echo "  git -C \"$ROOT_DIR\" push origin \"$TAG_NAME\""
  else
    echo -e "Membuat tag ${TAG_NAME}..."
    git -C "$ROOT_DIR" tag -a "$TAG_NAME" -m "Trigger mobile build: target=${TARGET}, config=${CONFIG}"
    echo -e "Push tag ke origin..."
    git -C "$ROOT_DIR" push origin "$TAG_NAME"
    echo -e "${GREEN}✓ Tag ${TAG_NAME} berhasil di-push ke origin!${NC}"
    echo -e "GitHub Actions akan secara otomatis mendeteksi tag ini dan memulai proses build."
  fi
fi

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}Pantau status build di:${NC}"
echo -e "  👉 ${CYAN}https://github.com/${REPO_SLUG}/actions${NC}"
echo -e "${GREEN}======================================================${NC}"
