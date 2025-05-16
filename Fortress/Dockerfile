FROM tomcat:8.5.20

# Install netcat and unzip
# Modified to handle deprecated stretch-updates repository
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
 && sed -i '/security.debian.org/d' /etc/apt/sources.list \
 && sed -i '/stretch-updates/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y netcat unzip ldap-utils \
 && rm -rf /var/lib/apt/lists/*

# Rest of your Dockerfile remains unchanged
ENV LDAP_HOST=archnav-ldap
ENV LDAP_PORT=10389
ENV FORTRESS_OPENLDAP_ACCELERATOR_ENABLED=false
ENV JAVA_OPTS="-Denable.openldap.accelerator=false -Daccess.factory.class=org.apache.directory.fortress.core.impl.AccessMgrImpl"
# Copy tomcat config
ADD tomcat-users.xml /usr/local/tomcat/conf/

# Copy catalina.sh (to allow JAVA_OPTS or hooks)
ADD catalina.sh /usr/local/tomcat/bin/
RUN chmod +x /usr/local/tomcat/bin/catalina.sh

# Copy fortress JAR
ADD fortress-realm-impl-2.0.3.jar /usr/local/tomcat/lib/
ADD fortress-realm-proxy-2.0.3.jar /usr/local/tomcat/lib/

# Required for Fortress Configuration
ADD commons-configuration-1.10.jar /usr/local/tomcat/lib/
ADD commons-lang-2.6.jar /usr/local/tomcat/lib/
ADD commons-logging-1.2.jar /usr/local/tomcat/lib/
ADD api-util-1.0.0-M23.jar /usr/local/tomcat/lib/

# New additions: api-all and log4j
ADD api-all-1.0.0-M33.jar /usr/local/tomcat/lib/
ADD log4j-api-2.11.1.jar /usr/local/tomcat/lib/
ADD log4j-core-2.11.1.jar /usr/local/tomcat/lib/

# Deploy WARs
ADD fortress-rest-2.0.3.war /usr/local/tomcat/webapps/
ADD fortress-web-2.0.3.war /usr/local/tomcat/webapps/
ADD fortress-core-2.0.3.jar /usr/local/tomcat/lib/
ADD https://repo1.maven.org/maven2/commons-pool/commons-pool/1.6/commons-pool-1.6.jar /usr/local/tomcat/lib/commons-pool-1.6.jar

# Add SLF4J logging support required by Fortress
ADD slf4j-api-1.7.25.jar /usr/local/tomcat/lib/
ADD slf4j-simple-1.7.25.jar /usr/local/tomcat/lib/

# Optional: override context.xml for manager app
COPY webappManager/context.xml /usr/local/tomcat/webapps/manager/META-INF/

# Copy startup update script
COPY update-fortress.sh /usr/local/tomcat/update-fortress.sh
RUN chmod +x /usr/local/tomcat/update-fortress.sh


# Expose port
EXPOSE 8080

# Start with update script
CMD ["/usr/local/tomcat/update-fortress.sh"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -q --spider http://localhost:8080/ || exit 1

FROM maven:3.8-openjdk-11 as builder


WORKDIR /build
RUN { \
    wget https://archive.apache.org/dist/directory/fortress/dist/2.0.0-RC1/fortress-web-2.0.0-RC1-source-release.zip -O fortress-web.zip && \
    unzip fortress-web.zip && \
    cd fortress-web-2.0.0-RC1; \
    } || { \
    git clone https://github.com/apache/directory-fortress-enmasse.git fortress-web-2.0.0-RC1 && \
    cd fortress-web-2.0.0-RC1 && \
    git checkout 2.0.0-RC1; \
    } && \
    mvn clean package -DskipTests

FROM tomcat:8.5-jre11

# Install Tomcat Manager app first
RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.87/bin/extras/catalina-jmx-remote.jar -P /usr/local/tomcat/lib/ && \
    wget https://repo1.maven.org/maven2/org/apache/tomcat/tomcat-catalina/8.5.87/tomcat-catalina-8.5.87.jar -P /usr/local/tomcat/lib/

# Then copy Fortress Web
COPY --from=builder /build/fortress-web-*/target/fortress-web-*.war /usr/local/tomcat/webapps/fortress-web.war
COPY fortress.properties /usr/local/tomcat/conf/

# Configure access
RUN echo '<tomcat-users>\
  <role rolename="manager-gui"/>\
  <role rolename="manager-script"/>\
  <user username="admin" password="admin" roles="manager-gui,manager-script"/>\
</tomcat-users>' > /usr/local/tomcat/conf/tomcat-users.xml && \
    mkdir -p /usr/local/tomcat/webapps/manager/META-INF && \
    echo '<Context antiResourceLocking="false" privileged="true">\
  <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />\
</Context>' > /usr/local/tomcat/webapps/manager/META-INF/context.xml

EXPOSE 8080
