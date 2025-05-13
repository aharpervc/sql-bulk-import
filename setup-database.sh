#!/bin/bash
set -e
set -o pipefail

CONTAINER_NAME="${CONTAINER_NAME:-mssql}"

if ! docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: This script requires a container named '${CONTAINER_NAME}' to be running"
  exit 1
fi

docker exec -it ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Testing123@@ -C -Q 'create database [test_database]' 2> /dev/null
