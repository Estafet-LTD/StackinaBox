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
search cluster.local
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
$ firewall-cmd --permanent --add-port=53/tcp # dns
$ firewall-cmd --permanent --add-port=53/udp # dns
$ firewall-cmd --permanent --add-port=8081/tcp # used by nexus
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
$ echo "search cluster.local" > /etc/origin/node/resolv.conf
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

* Next, you must trust the certificates being used for the registry on your host system to allow the host to push and pull images. The certificates referenced were created when you secured your registry.

```
$ mkdir /etc/docker/certs.d/docker-registry-default.apps.ocp.thales.com
$ cp /etc/origin/node/client-ca.crt /etc/docker/certs.d/docker-registry-default.apps.ocp.thales.com
$ systemctl restart docker 
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

* install required packages

```
$ yum -y install git wget vim bash-completion mariadb-server
```

* Ensure relevant files are in /home/engineer/ocp:

```
gitea.ini
gitea.service
setup-gitea.sh
```

* run the script to pull the archive, unzip it, and create the service

```
/home/engineer/ocp/setup-gitea.sh
```

* Create a gitea user via the Register option at http://ocp.thales.com:3000/user/sign_up

Username: engineer
Email address: engineer@ocp.thales.com
Password: Passw0rd!

* Test the gitea connection from another VM

```
curl http://ocp.thales.com:3000
```

### Install Jenkins CI-CD container and extra plugins

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

* install sonar scanner plugin and maven

```
mkdir /srv/nfs/var/lib/jenkins/tools/M3
wget http://repo.thales.com/jenkins-plugins/maven-plugin.hpi # may not be necessary
wget http://repo.thales.com/jenkins-plugins/sonar.hpi
wget http://repo.thales.com/jenkins-plugins/apache-maven-3.6.3-bin.tar.gz
mv maven-plugin.hpi /srv/nfs/jenkins/plugins
mv sonar.hpi /srv/nfs/jenkins/plugins 
tar xzf apache-maven-3.6.3-bin.tar.gz --directory=/srv/nfs/jenkins/tools/M3
oc rollout latest dc/jenkins-2-rhel7 -n=ci-cd # resar jenkins pod
```

* Update Jenkins configuration

Via Sonarqube console:

Create a user named jenkins and login
Create a token for the user and copy to the clipboard

Via Console:

In Manage Jenkins | Global Tools Configuration | add Maven - name it 'M3' - maven home is /var/lib/jenkins/tools/M3/apache-maven-3.6.3/

In Manage Jenkins | Configure System - under SonarQube section tick the box Enable injection of SonarQube server configuration as build environment variables and fill in server details - note the url for the server should be the internal one (ending in .svc). 

Also add the credential which will be the token created by SonarQube. 

### Install Kafka cluster

* Ensure files are in /home/engineer/ocp/pods:

```
kafka-pv.yaml
zoo-pv.yaml
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

### Install Sonarqube pods and extra plugins

* Ensure files are in /home/engineer/ocp/pods:

```
load-sonarqube-images.sh
sonarqube-postgresql-template.yaml
sonarqube-deployment.sh
sonarqube-pv.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/sonarqube-deployment.sh
```

* Install plugins for sonarqube (example java plugin)

```
mkdir /srv/nfs/sonarqube/plugins # mkdir if this is first time
wget http://repo.thales.com/sonar-plugins/sonar-java-plugin-5.8.0.15699.jar # example for java
mv sonar-java-plugin-5.8.0.15699.jar /srv/nfs/sonarqube/plugins
oc rollout latest dc/sonar -n=sonarqube # redeploy the sonar pod for the plugin to be loaded
```

### Reopen firewalls

Installation of OCP closes some of the ports that were opened previously and switches from firewalld to iptables

* Open ports so that IDE can connect:

```
iptables -I INPUT -p tcp --dport 3000 -j ACCEPT # gitea
iptables -I INPUT -p tcp --dport 8081 -j ACCEPT # nexus
iptables -I INPUT -p tcp --dport 53 -j ACCEPT # dns
iptables -I INPUT -p udp --dport 53 -j ACCEPT # dns
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

