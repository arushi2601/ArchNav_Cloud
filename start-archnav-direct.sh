#!/bin/bash

# Wait for MySQL and Fortress
echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "Waiting for MySQL..."
  sleep 2
done
echo "MySQL is available"

echo "Waiting for Fortress at $FORTRESS_HOST:$FORTRESS_PORT..."
until nc -z "$FORTRESS_HOST" "$FORTRESS_PORT"; do
  echo "Waiting for Fortress..."
  sleep 2
done
echo "Fortress is available"

# Set all Java-related environment variables explicitly
export JAVA_HOME=/usr/java
export AS_JAVA=/usr/java
export PATH=$JAVA_HOME/bin:$PATH

# Set GlassFish environment
export AS_INSTALL=/glassfish5/glassfish
export AS_DEF_DOMAINS_PATH=/glassfish5/glassfish/domains

echo "Starting GlassFish directly with Java..."
cd /glassfish5/glassfish

# Start GlassFish directly using Java
exec $JAVA_HOME/bin/java \
    -jar /glassfish5/glassfish/modules/glassfish.jar \
    -domaindir /glassfish5/glassfish/domains \
    -domainname domain1 \
    -instancename server \
    -upgrade false \
    -type DAS