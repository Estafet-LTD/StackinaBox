# Install gitea - NB this has now been scripted - see ocp-setup.md

The following steps are based on instructions at https://computingforgeeks.com/how-to-install-gitea-self-hosted-git-service-on-centos-7-with-nginx-reverse-proxy/

* install required packages

```
$ yum -y install git wget vim bash-completion mariadb-server
```

* add git user account to be used by gitea

```
$ sudo useradd \
   --system \
   --shell /bin/bash \
   --comment 'Git Version Control' \
   --create-home \
   --home-dir /home/git \
   git
```

* create directory structure
```
$ mkdir -p /etc/gitea /var/lib/gitea/{custom,data,indexers,public,log}
$ chown git:git /var/lib/gitea/{data,indexers,log}
$ chmod 750 /var/lib/gitea/{data,indexers,log}
$ chown root:git /etc/gitea
$ chmod 770 /etc/gitea
```

* install and configure maria db service

```
$ systemctl enable mariadb.service
$ systemctl start mariadb.service

$ sudo mysql_secure_installation
# when prompted enter the following details
Enter current password for root (enter for none): Just press the Enter
Set root password? [Y/n]: Y
New password: rootpassw0rd
Re-enter new password: rootpassw0rd
Remove anonymous users? [Y/n]: Y
Disallow root login remotely? [Y/n]: Y
Remove test database and access to it? [Y/n]:  Y
Reload privilege tables now? [Y/n]:  Y

$ systemctl restart mariadb.service


```

* create a database for gitea

```
$ mysql -u root -p
Enter password: rootpassw0rd
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 608168
Server version: 10.3.9-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE DATABASE gitea;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'localhost' IDENTIFIED BY "giteapassw0rd";
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.002 sec)
MariaDB [(none)]> exit
Bye
```

* install and configure gitea

```
$ wget repo.thales.com/gitea/gitea
$ chmod +x gitea
$ mv gitea /usr/bin/gitea
$ gitea --version
Gitea version 1.11.0 built with GNU Make 4.1, go1.13.7 : bindata, sqlite, sqlite_unlock_notify
```

* Create a service for gitea and populate it

```
touch /etc/systemd/system/gitea.service  create the service file
cat /etc/systemd/system/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target
After=mariadb.service

[Service]
# Modify these two values and uncomment them if you have
# repos with lots of files and get an HTTP error 500 because
# of that
###
#LimitMEMLOCK=infinity
#LimitNOFILE=65535
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/bin/gitea web -c /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
# If you want to bind Gitea to a port below 1024 uncomment
# the two values below
###
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

* Via a web browser go to http://ocp.thales.com/install and set up the gitea information 
Alternatively edit the app.ini file

```
$ cat /etc/gitea/app.ini

APP_NAME = Gitea: Git with a cup of tea
RUN_USER = git
RUN_MODE = prod

[oauth2]
JWT_SECRET = 59DFTWnPjQNUpJ9kYBbBddy_jR5TRq6hzhWFfhttchQ

[security]
INTERNAL_TOKEN = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYmYiOjE1ODE2ODY1OTl9.nK0PM79aP6au0fS3X5Hb0odXI3Ci99OVUx-gqzddbvA
INSTALL_LOCK   = true
SECRET_KEY     = zc6R78wo1mnHpyI8WtX1vb6cOn0bRdEdlW0oearcBh5nPGR3VLlRqcbbJeOdE6Rt

[database]
DB_TYPE  = mysql
HOST     = ocp.thales.com:3306
NAME     = gitea
USER     = gitea
PASSWD   = giteapassw0rd
SSL_MODE = disable
CHARSET  = utf8
PATH     = /var/lib/gitea/data/gitea.db

[repository]
ROOT = /home/git/gitea-repositories

[server]
SSH_DOMAIN       = localhost
DOMAIN           = localhost
HTTP_PORT        = 3000
ROOT_URL         = http://ocp.thales.com:3000/
DISABLE_SSH      = false
SSH_PORT         = 22
LFS_START_SERVER = true
LFS_CONTENT_PATH = /var/lib/gitea/data/lfs
LFS_JWT_SECRET   = JP9NiIw3eDR-TXfN5NfnWbhM2pbUuDkNLpHOi89p3UU
OFFLINE_MODE     = false

[mailer]
ENABLED = false

[service]
REGISTER_EMAIL_CONFIRM            = false
ENABLE_NOTIFY_MAIL                = false
DISABLE_REGISTRATION              = false
ALLOW_ONLY_EXTERNAL_REGISTRATION  = false
ENABLE_CAPTCHA                    = false
REQUIRE_SIGNIN_VIEW               = false
DEFAULT_KEEP_EMAIL_PRIVATE        = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
DEFAULT_ENABLE_TIMETRACKING       = true
NO_REPLY_ADDRESS                  = noreply.localhost

[picture]
DISABLE_GRAVATAR        = false
ENABLE_FEDERATED_AVATAR = true

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[session]
PROVIDER = file

[log]
MODE      = file
LEVEL     = info
ROOT_PATH = /var/lib/gitea/log
```

* Create a gitea user via the Register option at http://ocp.thales.com:3000/user/sign_up

Username: engineer
Email address: engineer@ocp.thales.com
Password: Passw0rd!

* Open the firewall for gitea from other network users

```
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
```

* Test the gitea connection from another VM

```
curl http://ocp.thales.com:3000
```
