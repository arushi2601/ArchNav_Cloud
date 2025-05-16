This project provides a containerized setup of the ArchNav application, consisting of multiple components including MySQL, ApacheDS (LDAP), Tomcat (Fortress), and GlassFish (ADF-enabled EAR deployment). 
The system has been migrated from a manual local installation to a fully Docker-based architecture, simulating a cloud-ready design.

## 📦 Components

| Service   | Description                                                 |
|-----------|-------------------------------------------------------------|
| MySQL     | Stores the Archemy schema and procedures                    |
| ApacheDS  | Provides LDAP authentication for Fortress                   |
| Tomcat    | Hosts Fortress-Web and Fortress-REST WAR applications       |
| GlassFish | Hosts the `archemy.ear` Oracle ADF application              |

## Quick Start

### Clone the Repository

```bash
git clone <repo-url>
cd project-root/
docker-compose up --build
```
