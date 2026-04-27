#!/bin/bash
# Create Solid Queue/Cache/Cable databases on Postgres init.
# Postgres image runs *.sh / *.sql in /docker-entrypoint-initdb.d/ on first boot.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE littlestars_production_cache;
  CREATE DATABASE littlestars_production_queue;
  CREATE DATABASE littlestars_production_cable;
EOSQL
