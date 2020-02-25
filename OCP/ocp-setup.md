# Installing the OCP VM

## VM config

24 Gb RAM

8 cores

60 Gb hard disk
40 Gb nvme drive (for docker storage)

RHEL 7 + GUI + Development tools + System Admin tools

Host only connection in VMWare

root / rootpassw0rd

engineer / passw0rd

hostname: ocp.thales.com

IP: 10.0.2.1 

## Network setup

Set up the host only network by the following:

* Update /etc/hosts file and add the following lines

```
10.0.2.1 ocp.thales.com
10.0.2.2 ide.thales.com
10.0.2.3 repo.thales.com
```

* Identify the network adapter for host only managed by VMWare (e.g. ens33)

* Edit the file at /etc/sysconfig/network-scripts/ifcfg-<adapter name>
    
 ```
# cat /etc/sysconfig/network-scripts/ifcfg-<adapter name>
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
GATEWAY=10.0.2.1
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=<adapter name>
DEVICE=<adapter name>
ONBOOT=yes
IPV6_PRIVACY=no
IPADDR=10.0.2.1
PREFIX=24
PEERDNS=no
DNS1=10.0.2.1
```   

* Add a file under /etc/dnsmasq.d named ocp.thales.com.conf. This will configure the dnsmasq wildcard

``` 
# cat /etc/dnsmasq.d/ocp.thales.com.conf
address=/ocp.thales.com/10.0.2.1
``` 

* ensure that /etc/resolv.conf refers to the address that dnsmasq is listening on

```
$ cat /etc/resolv.conf
nameserver 10.0.2.1
```

* Ensure that libvirtd is not running a separate dnsmasq service nd kill it if so [optional]

```
$ systemctl status libvirtd.service # check if this is active and has a running dnsmasq
$ systemctl disable libvirtd.service
$ systemctl stop libvirtd.service
$ netstat -lnp | grep ":53 " # find the 'other dnsmasq service
$ kill -9 <PID>
$ reboot
```

* Start the 'proper' dnsmasq service [optional]

```
$ systemctl enable dnsmasq
$ systemctl start dnsmasq
$ systemctl status dnsmasq 
# now prove that the 'correct' dnsmasq is working
$ dig repo.thales.com # should resolve
$ dig anything.ocp.thales.com # should resolve to ocp.thales.com on 10.0.2.1
```

## Set up

 The below is based on steps from https://blog.openshift.com/openshift-all-in-one-aio-for-labs-and-fun/ while keeping one eye on https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-installing-openshift
 
 Steps follow:
 
 ### Install required packages
 
* Add engineer to sudoers group
 
* Ensure Repo and Registry VMs are accessible (ping)

* Ensure _ifconfig_ resolves with static IP address - run _sudo dhclient_ if necessary

* create passwordless ssh key and copy to ocp.example.com then test ssh to self

```
$ sudo -iH

$ ssh-keygen

$ ssh-copy-id ocp.thales.com
```

* create file _ose.repo_ in folder /etc/yum/repos.d  (see sample in folder)
**NB when using Ansible 2.8 the OSE build fails with an error around the persistent volume for registry not being created. For this reason the build was done using Ansible 2.6**

* Install ansible etc.

```
$ yum -y install atomic-openshift-clients openshift-ansible
```

### Install docker

* Install docker

```
$ yum install docker-1.13.1
$ docker version
```

* Configure storage for Docker

```
$ systemctl stop docker
$ container-storage-setup --reset
$ rm -rf /var/lib/docker/

# cat <<EOF > /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=/dev/nvme0n1
CONTAINER_ROOT_LV_NAME=docker-lv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=docker-vg
EOF

$ docker-storage-setup

```

* Check the results

```
$ lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda             8:0    0   60G  0 disk 
├─sda1          8:1    0    1G  0 part /boot
└─sda2          8:2    0   59G  0 part 
  ├─rhel-root 253:0    0 35.6G  0 lvm  /
  ├─rhel-swap 253:1    0    6G  0 lvm  [SWAP]
  └─rhel-home 253:2    0 17.4G  0 lvm  /home
sr0            11:0    1  4.2G  0 rom  /run/media/engineer/RHEL-7.7 Server.x86_6
nvme0n1       259:0    0   40G  0 disk 
└─nvme0n1p1   259:1    0   40G  0 part 
  └─docker--vg-docker--lv
              253:3    0   40G  0 lvm  /var/lib/docker
```

* Restart docker and enable docker

```
$ systemctl restart docker
$ systemctl enable docker
```

### opening firewalls

[a open Windows Defender firewall for the VM adapter]

Windows Firewall | Advanced Settings | Windows Defender Firewall Properties | Protected Network Connections | Uncheck the correct VMWare Network Adapter

[b open VM firewall to outside]

```
$ firewall-cmd --permanent --add-port=8443/tcp
$ firewall-cmd --permanent --add-port=80/tcp
$ firewall-cmd --permanent --add-port=443/tcp
$ firewall-cmd --permanent --add-port=3000/tcp # used by gitea
$ firewall-cmd --permanent --add-port=9000/tcp # used by sonarqube
$ firewall-cmd --reload
```

### Create nfs storage for OCP

* Create nfs storage in the VM (these steps were taken from https://www.thegeekdiary.com/centos-rhel-7-configuring-an-nfs-server-and-nfs-client/):

```
$ yum install nfs-utils rpcbind # probably already installed

$ systemctl enable nfs-server
$ systemctl enable rpcbind
$ systemctl enable nfs-lock
$ systemctl enable nfs-idmap

$  systemctl start rpcbind
$  systemctl start nfs-server
$  systemctl start nfs-lock
$  systemctl start nfs-idmap

$ systemctl status nfs

$ mkdir /srv/nfs  # where the hosts file expects the storage to be

$ vi /etc/exports
/srv/nfs *(rw) 

$ exportfs -r   # export the files for storage

$  systemctl restart nfs-server

$ firewall-cmd --add-service=nfs --zone=internal --permanent
$ firewall-cmd --add-service=mountd --zone=internal --permanent
$ firewall-cmd --add-service=rpc-bind --zone=internal --permanent
```

### Set up trust for self signed cert in Repo VM

* Copy the registry.crt file created in the _Repo VM_ for the secure docker registry to a shared folder

* Copy the cert file to /etc/pki/ca-trust/source/anchors folder on the _OCP VM_

* run command to update the global trust settings

```
$ update-ca-trust

```

* restart docker on the VM to refresh based on the global trust settings

```
$ systemctl restart docker
```

* test login 

```
$ docker login repo.thales.com:5000
Username: engineer
Password: 
Login Succeeded

$ docker logout repo.thales.com:5000
Removing login credentials for repo.thales.com:5000
```

### Install OCP

* add hosts file to /etc/ansible (default location) - example file is in this github folder

* Run prerequisites playbook (assumes hosts file is in default location)

```
$ ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
```

* A file needs to be created in /etc/origin/node/resolv.conf for the sdn pod to work correctly before running the deploy playbook (create the folder the first time)

```
$ echo "nameserver 10.0.2.1" > /etc/origin/node/resolv.conf
```

* Run the deploy playbook (assumes hosts file is in default location)

```
$ ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
```

* Test that the OCP cluster is up and running

```
$ oc whoami
system:admin
$ oc get pods --all-namespaces
```

* Add cluster admin rights to the developer user

```
$ oc adm policy add-cluster-role-to-user admin developer
```

* To uninstall and clean up: (assumes hosts file is in default location)

```
$ ansible-playbook  /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
```

### Install nexus

* Ensure relevant files are in /home/engineer/ocp:

```
nexus.service
setup-nexus.sh
```

* run the script to pull the archive, unzip it, and create the service

```
/home/engineer/ocp/setup-nexus.sh
```

### Install gitea

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

### Install Jenkins CI-CD container

* Ensure files are in /home/engineer/ocp/pods:

```
jenkins-pv.yaml
jenkins-pvc.yaml
jenkins-deployment.sh
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/jenkins-deployment.sh
```

### Install Kafka cluster

* Ensure files are in /home/engineer/ocp/pods:

```
kafka-pv.yaml
zookeeper-pv.yaml
kafka-deployment.sh
kafka-persistent-ocp-thales.yaml
load-strimzi-images.sh
050-deployment-strimzi-thales-ocp.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/kafka-deployment.sh
```

#### smoke test kafka in container terminals

open two terminals on the kafka cluster pod that was created (e.g. my-cluster-kafka-0)

in the first terminal type the following. This will produce a command prompt (>) where you can type messages:

```
$ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-topic
```

in the second terminal type the following. This should echo the messages typed in the first terminal:

```
$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --from-beginning
```

Once these are open anything typed into the first, producer terminal will appear in the second, consumer terminal

### Install Sonarqube pods

* Ensure files are in /home/engineer/ocp/pods:

```
load-sonarqube-images.sh
sonarqube-postgresql-template.yaml
sonarqube-deployment.sh
sonarqube-pv.yaml
sonarqube-pvc.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/sonarqube-deployment.sh
```

## Stopping the OCP Cluster

```
$ sudo oc adm drain -l "a!=" --delete-local-data --ignore-daemonsets
$ sudo mv /etc/origin/node/pods /etc/origin/node/pods.stop
$ sudo systemctl stop atomic-openshift-node
$ sudo docker ps -q | xargs docker stop --time 30 # this takes a while to shutdown the sdn by the looks of it
$ sudo systemctl stop docker
```

## Restarting the OCP Cluster

```
<add default route>
$ sudo systemctl start atomic-openshift-node # failed to start automatically on boot for some reason (maybe the route)
$ sudo systemctl start docker # already started but for completeness
$ sudo mv /etc/origin/node/pods.stop /etc/origin/node/pods
… <have to wait until cluster is up now before can uncordon it> … # might have to use oc status or oc whoami in a loop to wait until ready
$ sudo oc adm uncordon -l "a!="
```

