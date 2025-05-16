FROM mysql:5.7

# Environment variables for MySQL setup
ENV MYSQL_ROOT_PASSWORD=password
ENV MYSQL_DATABASE=archemy
ENV MYSQL_USER=archnav
ENV MYSQL_PASSWORD=archnav

# Copy the schema file for initialization
COPY DatabaseImport.sql /docker-entrypoint-initdb.d/

# Expose MySQL port
EXPOSE 3306