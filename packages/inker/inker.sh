#!@shell@
# shellcheck shell=bash
# Inker backend launcher.
#
# Inker resolves both its read-only assets and its writable uploads relative to
# the current working directory (process.cwd()). We therefore prepare a data
# directory (default: $PWD, override with INKER_DATA_DIR), link the bundled
# assets into it, create the uploads/logs tree, and run from there.
set -eu

APP="@app@"
DATA_DIR="${INKER_DATA_DIR:-$PWD}"

mkdir -p \
  "$DATA_DIR/uploads/screens" \
  "$DATA_DIR/uploads/firmware" \
  "$DATA_DIR/uploads/widgets" \
  "$DATA_DIR/uploads/captures" \
  "$DATA_DIR/uploads/drawings" \
  "$DATA_DIR/logs"

ln -sfn "$APP/assets" "$DATA_DIR/assets"
cd "$DATA_DIR"

# Puppeteer needs a writable HOME for its config.
export HOME="${HOME:-$DATA_DIR}"
export PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-@chromium@}"

export PRISMA_QUERY_ENGINE_LIBRARY="@queryLib@"
export PRISMA_SCHEMA_ENGINE_BINARY="@schemaBin@"
export PRISMA_QUERY_ENGINE_BINARY="@queryBin@"

# Apply the schema to the database, as upstream's entrypoint does on each start.
# Tolerate failure (e.g. a fresh database that is not reachable yet).
if [ "${INKER_SKIP_DB_PUSH:-0}" != "1" ]; then
  "@node@" "$APP/node_modules/prisma/build/index.js" db push --skip-generate \
    --schema "$APP/prisma/schema.prisma" \
    || echo "[inker] prisma db push failed (continuing)"
fi

exec "@node@" "$APP/dist/main.js" "$@"
