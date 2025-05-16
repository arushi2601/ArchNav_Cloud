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

# Verify domain structure
echo "Verifying domain structure..."
echo "Contents of /glassfish5/glassfish/domains/domain1:"
ls -la /glassfish5/glassfish/domains/domain1/
echo "Contents of /glassfish5/glassfish/domains/domain1/config:"
ls -la /glassfish5/glassfish/domains/domain1/config/

# Update domain.xml with custom configurations
echo "Updating domain.xml with custom configurations..."
# Here you would add your specific domain.xml updates using sed commands
# For example, to update the port to 9999:
sed -i 's/port="8080"/port="9999"/g' /glassfish5/glassfish/domains/domain1/config/domain.xml

# Start GlassFish in verbose/foreground mode to keep container running
echo "Starting GlassFish in foreground mode..."
cd /glassfish5/glassfish/bin

# Use 'start-domain --verbose' which runs in foreground
export AS_JAVA=$JAVA_HOME
exec ./asadmin start-domain --verbose --domaindir /glassfish5/glassfish/domains domain1