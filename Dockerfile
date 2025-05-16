FROM ubuntu:16.04

# --------------------------
# System Setup
# --------------------------
RUN apt-get update && \
    apt-get install -y \
        unzip \
        curl \
        wget \
        netcat \
        mysql-client \
        openjdk-8-jdk \
        libaio1 && \
    rm -rf /var/lib/apt/lists/*

# --------------------------
# Oracle Instant Client - More reliable download
# --------------------------
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    curl -fL https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-basiclite-linux.x64-21.12.0.0.0dbru.zip \
        -H "Cookie: oraclelicense=accept-securebackup-cookie" -o instantclient-basiclite.zip && \
    curl -fL https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-tools-linux.x64-21.12.0.0.0dbru.zip \
        -H "Cookie: oraclelicense=accept-securebackup-cookie" -o instantclient-tools.zip && \
    unzip instantclient-basiclite.zip && \
    unzip instantclient-tools.zip && \
    rm *.zip && \
    ln -s instantclient_* instantclient && \
    echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

ENV PATH="/opt/oracle/instantclient:$PATH"
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient:$LD_LIBRARY_PATH"

# --------------------------
# Java 8 Configuration
# --------------------------
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV AS_JAVA=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN mkdir -p /usr/lib/jvm && \
    ln -sf $JAVA_HOME /usr/lib/jvm/java-8 && \
    ln -sf $JAVA_HOME/bin/java /usr/bin/java


# --------------------------
# Alternative GlassFish installation
# --------------------------
RUN apt-get update && \
    apt-get install -y wget unzip && \
    wget -q https://repo1.maven.org/maven2/org/glassfish/main/distributions/glassfish/5.0.1/glassfish-5.0.1.zip \
        -O /tmp/glassfish.zip && \
    unzip -q /tmp/glassfish.zip -d /usr/local && \
    rm /tmp/glassfish.zip && \
    chmod -R 755 /usr/local/glassfish5/bin && \
    ln -s /usr/local/glassfish5 /glassfish5
ENV GF_HOME=/glassfish5
ENV PATH=$PATH:$GF_HOME/bin

# --------------------------
# GlassFish Configuration - More robust XML editing
# --------------------------
RUN cd /glassfish5/glassfish/domains/domain1/config && \
    cp domain.xml domain.xml.backup && \
    awk '/<resources>/ { print; print "\
    <jdbc-connection-pool datasource-classname=\"com.mysql.jdbc.jdbc2.optional.MysqlXADataSource\" \
                          name=\"MySQLConnPool\" \
                          res-type=\"javax.sql.XADataSource\" \
                          is-isolation-level-guaranteed=\"false\"> \
      <property name=\"user\" value=\"archemy\"/> \
      <property name=\"password\" value=\"archnav\"/> \
      <property name=\"DatabaseName\" value=\"archemy\"/> \
      <property name=\"ServerName\" value=\"archnav-mysql\"/> \
      <property name=\"port\" value=\"3306\"/> \
      <property name=\"useSSL\" value=\"false\"/> \
    </jdbc-connection-pool> \
    <jdbc-resource pool-name=\"MySQLConnPool\" jndi-name=\"jdbcMySQLDataSource\"/> \
    <jdbc-resource pool-name=\"MySQLConnPool\" jndi-name=\"jdbc/archemyapp\"/>"; next } 1' domain.xml.backup > domain.xml

# --------------------------
# Direct ADF Essentials Copy
# --------------------------

# Create target directory first
RUN mkdir -p /glassfish5/glassfish/domains/domain1/lib/

# Copy all files directly (replace 'adf-essentials/' with your directory)
COPY adf-essentials/ /glassfish5/glassfish/domains/domain1/lib/

# Set proper permissions
RUN chmod -R 755 /glassfish5/glassfish/domains/domain1/lib/
#__________________________________________________
# --------------------------
# EAR File Deployment with Full Dependencies
# --------------------------
# --------------------------
# Skip EAR Processing
# --------------------------

# 1. Simply verify the EAR file exists
COPY archemy.ear /glassfish5/glassfish/domains/domain1/autodeploy/
RUN test -f /glassfish5/glassfish/domains/domain1/autodeploy/archemy.ear && \
    echo "EAR file present - skipping processing" || \
    { echo "ERROR: EAR file missing"; exit 1; }

# 2. Optional: Verify basic EAR file integrity (without processing)
RUN unzip -tq /glassfish5/glassfish/domains/domain1/autodeploy/archemy.ear || \
    echo "Warning: EAR file verification failed - continuing anyway"
# --------------------------
# Final Setup
# --------------------------
COPY start-archnav-asadmin.sh /start-archnav.sh
RUN chmod +x /start-archnav.sh && \
    chmod +x /glassfish5/bin/asadmin

EXPOSE 8080 4848

ENV DB_HOST=archnav-mysql \
    DB_PORT=3306 \
    DB_USER=archemy \
    DB_PASSWORD=archnav \
    DB_NAME=archemy \
    FORTRESS_HOST=archnav-fortress \
    FORTRESS_PORT=8080 \
    LDAP_HOST=archnav-ldap \
    LDAP_PORT=10389

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["/start-archnav.sh"]