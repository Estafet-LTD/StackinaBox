in/bash
set -ex

GITEA_SETUP_SQL="/tmp/gitea_setup.sql"
SECURE_SETUP_SQL="/tmp/gitea_sec_setup.sql"
GITEA_SERVICE_FILE="/home/engineer/ocp/gitea.service"
GITEA_CONFIG_FILE="/home/engineer/ocp/gitea.ini"


# Ensure the database is ready
systemctl start mariadb.service

# "Secure" the database

# Get temporary password
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mariadb/mariadb.log | awk '{print $11}')

# Make sure that NOBODY can access the server without a password
# Kill the anonymous users
# Kill off the demo database
# Make our changes take effect
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd para
cat > ${SECURE_SETUP_SQL} << __SECURE_SQL_EOF__
UPDATE mysql.user SET Password=PASSWORD('r00tpassw0rd') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
__SECURE_SQL_EOF__
mysql -sfu root -p${TEMP_PASSWORD} < ${SECURE_SETUP_SQL}

# Ensure we restart and enable
systemctl restart mariadb.service
systemctl enable mariadb.service

# Add Gitea database
cat > ${GITEA_SETUP_SQL} << __GITEA_SQL_EOF__
CREATE DATABASE gitea;
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost' IDENTIFIED BY "giteapassw0rd";
FLUSH PRIVILEGES;
__GITEA_SQL_EOF__
mysql -sfu root -pr00tpassw0rd < ${GITEA_SETUP_SQL}

# Set up Gitea users and directories
useradd \
   --system \
   --shell /bin/bash \
   --comment 'Git Version Control' \
   --create-home \
   --home-dir /home/git \
   git
mkdir -p /etc/gitea /var/lib/gitea/{custom,data,indexers,public,log}
chown git:git /var/lib/gitea/{data,indexers,log}
chmod 750 /var/lib/gitea/{data,indexers,log}
chown root:git /etc/gitea
chmod 770 /etc/gitea

# Install Gitea
wget repo.thales.com/gitea/gitea
chmod a+x gitea
mv gitea /usr/bin/gitea
gitea --version

# Add service
cp -fv ${GITEA_SERVICE_FILE} /etc/systemd/system/gitea.service

# Add options
cp -fv ${GITEA_CONFIG_FILE} /etc/gitea/app.ini

# Start and enable the service now
systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

# Open the firewall for gitea from other network users
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
#firewall-cmd --zone=public --add-service=http --permanent
#firewall-cmd --reload