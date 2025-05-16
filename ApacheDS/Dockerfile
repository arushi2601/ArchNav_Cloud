FROM ubuntu:16.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
    curl \
    ldap-utils \
    procps \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV APACHEDS_VERSION=2.0.0.AM25 \
    APACHEDS_ARCH=amd64 \
    APACHEDS_ARCHIVE=apacheds-2.0.0.AM25-amd64.deb \
    APACHEDS_DATA=/var/lib/apacheds \
    APACHEDS_INSTANCE=default

# Download and install ApacheDS
RUN curl -L https://archive.apache.org/dist/directory/apacheds/dist/${APACHEDS_VERSION}/${APACHEDS_ARCHIVE} -o ${APACHEDS_ARCHIVE} \
    && dpkg -i ${APACHEDS_ARCHIVE} \
    && rm ${APACHEDS_ARCHIVE}

# Create symlink for data directory
RUN ln -sf ${APACHEDS_DATA}-${APACHEDS_VERSION} ${APACHEDS_DATA}

# Copy bootstrap files
RUN mkdir -p /bootstrap
COPY apacheds-fortress.ldif /bootstrap/
COPY users.ldif /bootstrap/

# Patch ApacheDS Bug
# RUN sed -i 's/^creatorsName::.*/creatorsname: uid=admin,ou=system/' '/var/lib/apacheds/default/partitions/schema/ou=schema/cn=fortress.ldif'
# RUN sed -i '/^ W0g/d' '/var/lib/apacheds/default/partitions/schema/ou=schema/cn=fortress.ldif'

# Patch config.ldif with known admin password hash
# Hashed password = "secret", in ApacheDS SSHA format
RUN sed -i 's/userPassword: .*/userPassword: {SSHA}tI7n5sRmAlJ+/eBDIS1MTQxVYrwIfJkF/' ${APACHEDS_DATA}-${APACHEDS_VERSION}/${APACHEDS_INSTANCE}/conf/config.ldif || true

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Starting ApacheDS..."\n\
service apacheds-${APACHEDS_VERSION}-${APACHEDS_INSTANCE} start\n\
\n\
echo "Waiting for ApacheDS on port 10389..."\n\
until nc -z localhost 10389; do sleep 1; done\n\
\n\
echo "Importing Fortress schema..."\n\
ldapadd -x -H ldap://localhost:10389 -D "uid=admin,ou=system" -w secret -f /bootstrap/apacheds-fortress.ldif -c || true\n\
\n\
echo "Importing users..."\n\
ldapadd -x -H ldap://localhost:10389 -D "uid=admin,ou=system" -w secret -f /bootstrap/users.ldif -c || true\n\
\n\
echo "ApacheDS setup complete. Tailing log..."\n\
tail -F ${APACHEDS_DATA}-${APACHEDS_VERSION}/${APACHEDS_INSTANCE}/log/apacheds.log\n' > /bootstrap/start.sh && chmod +x /bootstrap/start.sh

# Expose port
EXPOSE 10389

# Entrypoint
ENTRYPOINT ["/bootstrap/start.sh"]
