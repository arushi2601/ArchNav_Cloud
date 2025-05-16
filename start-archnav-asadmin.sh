#!/bin/bash

# Wait for MySQL
echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "Waiting for MySQL..."
  sleep 2
done
echo "MySQL is available"

# Wait for Fortress
echo "Waiting for Fortress at $FORTRESS_HOST:$FORTRESS_PORT..."
until nc -z "$FORTRESS_HOST" "$FORTRESS_PORT"; do
  echo "Waiting for Fortress..."
  sleep 2
done
echo "Fortress is available"

# Set Java environment
export JAVA_HOME=/usr/java
export AS_JAVA=/usr/java
export PATH=$JAVA_HOME/bin:$PATH

echo "Java environment:"
echo "JAVA_HOME=$JAVA_HOME"
echo "AS_JAVA=$AS_JAVA"
which java
java -version

# Verify domain structure
echo "Verifying domain structure..."
ls -la /glassfish5/glassfish/domains/domain1/
ls -la /glassfish5/glassfish/domains/domain1/config/

# Work around asadmin Java detection issue by creating wrapper script
echo "Creating Java wrapper..."
cat > /glassfish5/glassfish/config/asenv.conf << EOF
AS_JAVA="/usr/java"
AS_IMQ_LIB="/glassfish5/mq/lib"
AS_IMQ_BIN="/glassfish5/mq/bin"
AS_CONFIG="/glassfish5/glassfish/config"
AS_INSTALL="/glassfish5/glassfish"
AS_DEF_DOMAINS_PATH="/glassfish5/glassfish/domains"
AS_DERBY_INSTALL="/glassfish5/javadb"
EOF

# Also create asenv.bat for completeness
cat > /glassfish5/glassfish/config/asenv.bat << EOF
set AS_JAVA=/usr/java
set AS_IMQ_LIB=/glassfish5/mq/lib
set AS_IMQ_BIN=/glassfish5/mq/bin
set AS_CONFIG=/glassfish5/glassfish/config
set AS_INSTALL=/glassfish5/glassfish
set AS_DEF_DOMAINS_PATH=/glassfish5/glassfish/domains
set AS_DERBY_INSTALL=/glassfish5/javadb
EOF

# Create a wrapper for Java to ensure it's found
mkdir -p /usr/lib/jvm/java-8-oracle/bin
ln -sf /usr/java/bin/java /usr/lib/jvm/java-8-oracle/bin/java
ln -sf /usr/java /usr/lib/jvm/java-8-oracle

# Set additional environment variables that GlassFish might check
export AS_JAVA_HOME=/usr/java
export JAVA_HOME=/usr/java
export JRE_HOME=/usr/java
export JDK_HOME=/usr/java

# Start GlassFish using asadmin with verbose output
echo "Starting GlassFish using asadmin..."
cd /glassfish5/glassfish/bin

# Use absolute path and ensure Java is found
export PATH=/usr/java/bin:$PATH
./asadmin start-domain --verbose domain1