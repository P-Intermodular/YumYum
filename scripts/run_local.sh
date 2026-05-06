#!/bin/bash
set -e

# Cambiamos al directorio raíz del proyecto (un nivel arriba de scripts/)
cd "$(dirname "$0")/.."

# Verificamos si flutter está en el PATH
if ! command -v flutter &> /dev/null; then
  echo "Error: 'flutter' no se encuentra en el PATH."
  exit 1
fi
FLUTTER_BIN=$(command -v flutter)

# 1. Cargar .env
if [ -f .env ]; then
  # Eliminamos los \r en caso de que se haya editado en Windows
  export $(grep -v '^#' .env | tr -d '\r' | xargs)
fi

# 2. Validaciones rápidas
if [[ -z "${SUPABASE_URL}" || -z "${SUPABASE_ANON_KEY}" ]]; then
  echo "Error: Faltan variables en el .env (SUPABASE_URL o SUPABASE_ANON_KEY)"
  exit 1
fi

echo "🚀 Iniciando Build de Producción para Web..."

# 3. Limpieza y preparación
$FLUTTER_BIN pub get
$FLUTTER_BIN clean

# Workaround para WSL: crear symlink de build a un directorio de Linux nativo para evitar error EPERM
rm -rf build
mkdir -p /tmp/YumYum_build
ln -s /tmp/YumYum_build build

# Workaround para el error FormatException en WSL:
# Windows (chrome.exe) imprime textos con codificación Windows (no UTF-8),
# lo que crashea a Flutter en Linux. Creamos un wrapper para silenciarlo.
CHROME_WIN_PATH="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
if [ ! -f "$CHROME_WIN_PATH" ]; then
  CHROME_WIN_PATH="/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
fi

if [ -f "$CHROME_WIN_PATH" ]; then
  echo '#!/bin/bash' > /tmp/chrome_wrapper.sh
  echo "\"$CHROME_WIN_PATH\" \"\$@\" > /dev/null 2>&1" >> /tmp/chrome_wrapper.sh
  chmod +x /tmp/chrome_wrapper.sh
  export CHROME_EXECUTABLE="/tmp/chrome_wrapper.sh"
fi

# 4. Lanzar la aplicación en Chrome (usando tus variables)
$FLUTTER_BIN run -d chrome --release --web-port=3000 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=APP_BASE_URL="${APP_BASE_URL:-http://localhost:3000}"

echo "✅ Ejecución finalizada."