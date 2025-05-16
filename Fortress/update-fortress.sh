#!/bin/bash
set -e

echo "=== Starting Fortress Update Script ==="

# Wait for LDAP to be available
LDAP_HOST=${LDAP_HOST:-archnav-ldap}
LDAP_PORT=${LDAP_PORT:-10389}
echo "[*] Waiting for LDAP server at ${LDAP_HOST}:${LDAP_PORT}..."

while ! nc -z "${LDAP_HOST}" "${LDAP_PORT}"; do
  sleep 1
done

echo "[*] Testing LDAP connection..."
if ldapsearch -h "${LDAP_HOST}" -p "${LDAP_PORT}" -D "uid=admin,ou=system" -w secret -b "dc=example,dc=com" -s base > /dev/null; then
  echo "[✔] Connected to LDAP server"
else
  echo "[✘] Failed to connect to LDAP server. Check host, port, or credentials."
  # Continue anyway, as we might want to debug
fi

# Extract and update fortress-web
WEB_DIR="/usr/local/tomcat/webapps/fortress-web-2.0.3"
WEB_WAR="/usr/local/tomcat/webapps/fortress-web-2.0.3.war"

if [ ! -d "${WEB_DIR}" ]; then
  echo "[*] fortress-web not yet deployed, extracting WAR..."
  mkdir -p "${WEB_DIR}"
  unzip -q "${WEB_WAR}" -d "${WEB_DIR}"
  
  # Modify context.xml to disable OpenLDAP accelerator
  if [ -f "${WEB_DIR}/META-INF/context.xml" ]; then
    echo "[*] Updating fortress-web context.xml to disable OpenLDAP accelerator..."
    # Insert context-param before Realm element
    sed -i 's|<Realm|<context-param>\n    <param-name>enable.openldap.accelerator</param-name>\n    <param-value>false</param-value>\n  </context-param>\n  <Realm|' "${WEB_DIR}/META-INF/context.xml"
  fi
  
  echo "[*] Updating fortress-web configuration..."
  sed -i "s/^host=localhost/host=${LDAP_HOST}/g" "${WEB_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^port=10389/port=${LDAP_PORT}/g" "${WEB_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^admin.user=.*/admin.user=uid=admin,ou=system/g" "${WEB_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^admin.pw=.*/admin.pw=secret/g" "${WEB_DIR}/WEB-INF/classes/fortress.properties"

  sed -i "s/^host=localhost/host=${LDAP_HOST}/g" "${WEB_DIR}/fortress.properties"
  sed -i "s/^port=10389/port=${LDAP_PORT}/g" "${WEB_DIR}/fortress.properties"
  sed -i "s/^admin.user=.*/admin.user=uid=admin,ou=system/g" "${WEB_DIR}/fortress.properties"
  sed -i "s/^admin.pw=.*/admin.pw=secret/g" "${WEB_DIR}/fortress.properties"
  # Add this line to disable OpenLDAP accelerator in properties file
  if ! grep -q "enable.openldap.accelerator=false" "${WEB_DIR}/WEB-INF/classes/fortress.properties"; then
    echo "enable.openldap.accelerator=false" >> "${WEB_DIR}/WEB-INF/classes/fortress.properties"
  fi
  echo "[✔] fortress-web configuration updated"
  
  # Rename WAR to prevent Tomcat from deploying it again
  mv "${WEB_WAR}" "${WEB_WAR}.original"
fi

# Extract and update fortress-rest
REST_DIR="/usr/local/tomcat/webapps/fortress-rest-2.0.3"
REST_WAR="/usr/local/tomcat/webapps/fortress-rest-2.0.3.war"

if [ ! -d "${REST_DIR}" ]; then
  echo "[*] fortress-rest not yet deployed, extracting WAR..."
  mkdir -p "${REST_DIR}"
  unzip -q "${REST_WAR}" -d "${REST_DIR}"
  
  # Modify context.xml to disable OpenLDAP accelerator
  if [ -f "${REST_DIR}/META-INF/context.xml" ]; then
    echo "[*] Updating fortress-rest context.xml to disable OpenLDAP accelerator..."
    # Insert context-param before Realm element
    sed -i 's|<Realm|<context-param>\n    <param-name>enable.openldap.accelerator</param-name>\n    <param-value>false</param-value>\n  </context-param>\n  <Realm|' "${REST_DIR}/META-INF/context.xml"
  fi
  
  echo "[*] Updating fortress-rest configuration..."
  sed -i "s/^host=localhost/host=${LDAP_HOST}/g" "${REST_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^port=10389/port=${LDAP_PORT}/g" "${REST_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^admin.user=.*/admin.user=uid=admin,ou=system/g" "${REST_DIR}/WEB-INF/classes/fortress.properties"
  sed -i "s/^admin.pw=.*/admin.pw=secret/g" "${REST_DIR}/WEB-INF/classes/fortress.properties"
  # Add this line to disable OpenLDAP accelerator in properties file
  if ! grep -q "enable.openldap.accelerator=false" "${REST_DIR}/WEB-INF/classes/fortress.properties"; then
    echo "enable.openldap.accelerator=false" >> "${REST_DIR}/WEB-INF/classes/fortress.properties"
  fi
  echo "[✔] fortress-rest configuration updated"
  
  # Rename WAR to prevent Tomcat from deploying it again
  mv "${REST_WAR}" "${REST_WAR}.original"
fi

# Start Tomcat
echo "[*] Starting Tomcat..."
exec /usr/local/tomcat/bin/catalina.sh run