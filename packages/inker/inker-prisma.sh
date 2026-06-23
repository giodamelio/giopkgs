#!@shell@
# Thin wrapper around Inker's bundled Prisma CLI, with the pinned engines and
# the bundled schema preconfigured. Example: inker-prisma migrate status
set -eu

APP="@app@"

export PRISMA_QUERY_ENGINE_LIBRARY="@queryLib@"
export PRISMA_SCHEMA_ENGINE_BINARY="@schemaBin@"
export PRISMA_QUERY_ENGINE_BINARY="@queryBin@"

exec "@node@" "$APP/node_modules/prisma/build/index.js" \
  --schema "$APP/prisma/schema.prisma" "$@"
