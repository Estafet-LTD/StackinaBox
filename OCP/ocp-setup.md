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

IP: 10.0.2.1 ocp.thales.com

## Set up

 The below is based on steps from https://blog.openshift.com/openshift-all-in-one-aio-for-labs-and-fun/ while keeping one eye on https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-installing-openshift
 
 Steps follow:
 
* Add engineer to sudoers group
 
* Ensure Repo and Registry VMs are accessible (ping)

* Ensure _ifconfig_ resolves with static IP address - run _sudo dhclient_ if necessary

* add ip address and hostname (op.example.com) to /etc/hosts file

* set up dns resolution with dnsmasq
  * set up a wildcard entry in a conf file below /etc/dnsmasq.d folder

```
$ cat /etc/dnsmasq.d/ocp.example.com.conf
address=/ocp.example.com/192.168.1.30
```

  * ensure that /etc/resolv.conf refers to the address that dnsmasq is listening on

```
$ cat /etc/resolv.conf
nameserver <ip address of VM>
```

* create passwordless ssh key and copy to ocp.example.com then test ssh to self

```
$ sudo -iH

$ ssh-keygen

$ ssh-copy-id ocp.example.com
```
* add default route

```
ip route add default via <ip address>
```

* create file _ose.repo_ in folder /etc/yum/repos.d  (see sample in folder)

* Install ansible etc.

```
$ yum -y install atomic-openshift-clients openshift-ansible
```

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

* Restart docker and enable docker

```
$ systemctl restart docker
$ systemctl enable docker
```

* Create nfs storage in the VM (these steps were taken from https://www.thegeekdiary.com/centos-rhel-7-configuring-an-nfs-server-and-nfs-client/):

```
# yum install nfs-utils rpcbind # probably not necessary

# systemctl enable nfs-server
# systemctl enable rpcbind
# systemctl enable nfs-lock
# systemctl enable nfs-idmap

#  systemctl start rpcbind
#  systemctl start nfs-server
#  systemctl start nfs-lock
#  systemctl start nfs-idmap

# systemctl status nfs

# mkdir /srv/nfs  # where the hosts file expects the storage to be

# vi /etc/exports
/srv/nfs *(rw) 

# exportfs -r   # export the files for storage

```

* add hosts file to /etc/ansible (default location) - example file is in this github repo

* Run prerequisites playbook (assumes hosts file is in default location)

```
# ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
```

* the docker config file in /etc/sysconfig/docker needs to have an insecure registry added (this is removed by the prerequisites playbook) - the registry is the address of the registry VM

```
cat /etc/sysconfig/docker
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS=' --selinux-enabled     --insecure-registry=172.30.0.0/16 --insecure-registry=192.168.141.132:5000   --signature-verification=False'

[output redacted]
```

* A file needs to be created in /etc/origin/node/resolv.conf for the sdn pod to work correctly before running the deploy playbook (create the folder the first time)

```
# echo "nameserver <ip address of host only adapter>" > /etc/origin/node/resolv.conf
```

* Run the deploy playbook (assumes hosts file is in default location)

```
# ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
```


* To uninstall and clean up: (assumes hosts file is in default location)

```
# ansible-playbook  /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
```

## Deployment into OCP

Creating a deployable application is possible by directly referencing the images in the docker registry VM 

* Create a new project jenkins then pull the image and create a new app

```
# oc new project jenkins
# docker pull 192.168.141.132:5000/openshift3/jenkins-2-rhel7:latest  # pull into local registry
# oc new-app --docker-image="192.168.141.132:5000/openshift3/jenkins-2-rhel7:latest"
```

* NB for Jenkins to work the default serviceaccount needs admin access to the project

```
oc policy add-role-to-user admin system:serviceaccount:<project name>:default
```

After this add a PVC as the default is not persistent - this can be done via the console: delete the old pvc and add a new one
Ensure that the image pull policy in the deployment config is set to IfNotPresent (edit the dc)

```
# oc set volume dc/jenkins-2-rhel7 --remove --name=jenkins-2-rhel7-volume-1 # name of volume created
# oc edit dc jenkins-2-rhel7   # and set ImagePullPolicy to IfNotPresent
```

## Stopping the OCP Cluster

```
# sudo oc adm drain -l "a!=" --delete-local-data --ignore-daemonsets
# sudo mv /etc/origin/node/pods /etc/origin/node/pods.stop
# sudo systemctl stop atomic-openshift-node
# sudo docker ps -q | xargs docker stop --time 30 # this takes a while to shutdown the sdn by the looks of it
# sudo systemctl stop docker
```

## Restarting the OCP Cluster

```
<add default route>
# sudo systemctl start atomic-openshift-node # failed to start automatically on boot for some reason (maybe the route)
# sudo systemctl start docker # already started but for completeness
# sudo mv /etc/origin/node/pods.stop /etc/origin/node/pods
… <have to wait until cluster is up now before can uncordon it> … # might have to use oc status or oc whoami in a loop to wait until ready
# sudo oc adm uncordon -l "a!="
```

