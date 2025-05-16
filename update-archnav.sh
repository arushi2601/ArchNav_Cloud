#!/bin/bash

# Wait for services to be available
echo "Waiting for MySQL at ${DB_HOST}:${DB_PORT}..."
until nc -z ${DB_HOST} ${DB_PORT}; do
  echo "Waiting for MySQL..."
  sleep 2
done
echo "MySQL is available"

echo "Waiting for Fortress at ${FORTRESS_HOST}:${FORTRESS_PORT}..."
until nc -z ${FORTRESS_HOST} ${FORTRESS_PORT}; do
  echo "Waiting for Fortress..."
  sleep 2
done
echo "Fortress is available"

# Update GlassFish configuration for database connection
echo "Updating GlassFish domain.xml..."
sed -i "s/jdbc:mysql:\/\/localhost:3306/jdbc:mysql:\/\/${DB_HOST}:${DB_PORT}/g" /glassfish5/glassfish/domains/domain1/config/domain.xml
echo "domain.xml updated successfully"

# Start Glassfish - this is the command from your first ENTRYPOINT
echo "Starting GlassFish..."
exec /glassfish5/glassfish/bin/asadmin start-domain --verbose