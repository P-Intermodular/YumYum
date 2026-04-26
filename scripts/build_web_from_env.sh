#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ENV_PATH="${ENV_PATH:-$PROJECT_ROOT/.env}"
readonly FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
readonly FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
readonly FLUTTER_CACHE_DIR="${FLUTTER_CACHE_DIR:-$PROJECT_ROOT/.render}"
readonly FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
readonly FLUTTER_DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/${FLUTTER_ARCHIVE}"
readonly FLUTTER_HOME="$FLUTTER_CACHE_DIR/flutter"
readonly FLUTTER_BIN="$FLUTTER_HOME/bin/flutter"

if [[ ! -f "$ENV_PATH" ]]; then
  echo "No existe $ENV_PATH. Usa .env.example como plantilla." >&2
  exit 1
fi

# Exportamos el .env versionado para reutilizar la misma configuracion
# tanto en local como en el build remoto.
set -a
# shellcheck disable=SC1090
source "$ENV_PATH"
set +a

for key in SUPABASE_URL SUPABASE_ANON_KEY; do
  if [[ -z "${!key:-}" ]]; then
    echo "Falta $key en $ENV_PATH." >&2
    exit 1
  fi
done

if [[ "${SUPABASE_ANON_KEY}" == "pon_aqui_tu_anon_key" ]]; then
  echo "Rellena SUPABASE_ANON_KEY en $ENV_PATH antes de compilar." >&2
  exit 1
fi

mkdir -p "$FLUTTER_CACHE_DIR"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Descargando Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})..."
  rm -rf "$FLUTTER_HOME"
  curl -fsSL "$FLUTTER_DOWNLOAD_URL" -o "$FLUTTER_CACHE_DIR/$FLUTTER_ARCHIVE"
  tar -xJf "$FLUTTER_CACHE_DIR/$FLUTTER_ARCHIVE" -C "$FLUTTER_CACHE_DIR"
  rm -f "$FLUTTER_CACHE_DIR/$FLUTTER_ARCHIVE"
fi

echo "Usando Flutter en $FLUTTER_BIN"
"$FLUTTER_BIN" --version
"$FLUTTER_BIN" config --enable-web >/dev/null

cd "$PROJECT_ROOT"

masked_key="${SUPABASE_ANON_KEY:0:8}"
echo "Supabase URL: $SUPABASE_URL"
echo "Supabase anon key cargada: ${masked_key}..."

"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
