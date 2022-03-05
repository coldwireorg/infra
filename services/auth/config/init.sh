#!/bin/bash
echo "loading tables..."
psql -U postgres -d hydra < /docker-entrypoint-initdb.d/tables.sql