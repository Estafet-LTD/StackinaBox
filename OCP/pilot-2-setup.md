# Set up for Pilot 2

Design for an all-in-one _disconnected_ install in the OpenShift VM requires another VM to contain the repositories and ne for the registry

## Creation of the Repository VM

### VM config

4 Gb RAM

2 cores

140 Gb hard disk

NAT connection (for internet)

Host only connection (for local access) 

NB may need to run dhclient on start up to force lease of (static) ip address

### Set up

This VM can be created with an internet connection as long as the OCP VM is disconnected

This VM will act as the Repository server when installing OCP in the OCP VM and also hold the registry of required images which will be saved to tars and made available to the OCP VM via shared folders

Create a shared folder via VMWare Player 

Follow basic instructions at https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-repo-server
with basic steps as follows:

* Obtain the required Red Hat repositories and save locally

* Add the Apache server which will serve the repositories to the OCP VM at build time

* Pull the required docker images into the registry using the scripts:

```
$ ./pull-ocp-base-images.sh
$ ./pull-ocp-opt-images.sh
$ ./pull-ocp-s2i-images.sh
```

* Save the required docker images into tar files on th eshared folder using the scripts:

```
$ cd /mnt/hgfs/SF #  shared folder
$ ./save-ocp-base-images.sh
$ ./save-ocp-opt-images.sh
$ ./save-ocp-s2i-images.sh
```

### Fix the IP Address on the host only network
Find the mac address of the H/O adapter for the VM under VM settings | network adapter | advanced

* Edit the file C:\ProgramData\VMware\vmnetdhcp.conf and add a segment at the end like:
N.B. this assumes NAT address - VMNet1 would be default for host-only

host VMnet1 {

    hardware ethernet _mac address of VM_;
    fixed-address _fixed IP address e.g. 192.168.141.134_;
   
   }
    
* stop and start the vmnet dhcp service:

```
net stop vmnetdhcp
net start vmnetdhcp
```

* Test the http server from outside the VM using the fixed ip address

http://192.168.141.134

## Creation of the Registry VM

### VM config

4 Gb RAM

2 cores

80 Gb hard disk

NAT connection (for internet)

Host only connection (for local access)

In the current (Pilot 2) instance this is a docker registry - maybe this will be satellite in future

NB may need to run dhclient on start up to force lease of (static) ip address

* Install docker

* Install docker registry which will serve the disconnected OCP

```
$ docker run -d -p 5000:5000 --restart=always --name registry registry:2
```


* Pull the required docker images into the registry using the scripts:

```
$ ./pull-ocp-base-images.sh
$ ./pull-ocp-opt-images.sh
$ ./pull-ocp-s2i-images.sh
```

* OPTIONAL Save the required docker images into tar files on the shared folder using the scripts NB this will not be necessary if the registry server is connected an dthere is no need for the registry to be held elsewhere

```
$ cd /mnt/hgfs/SF #  shared folder
$ ./save-ocp-base-images.sh
$ ./save-ocp-opt-images.sh
$ ./save-ocp-s2i-images.sh
```

* OPTIONAL Load the required docker images from the tar files on the shared folder using the scripts NB this will not be necessary if the registry server is connected and there is no need for the registry to be held elsewhere

```
$ cd /mnt/hgfs/SF #  shared folder
$ docker load -i ose3-images.tar
$ docker load -i ose3-optional-images.tar
$ docker load -i ose3-s2i-images.tar
```

* Tag all the images and push to the outward-facing docker registry

```
$ cd /mnt/hgfs/SF #  shared folder
$ ./tag-ocp-base-images.sh
$ ./tag-ocp-opt-images.sh
$ ./tag-ocp-s2i-images.sh
```


### Fix the IP Address
Find the mac address of the host only adapter for the VM under VM settings | network adapter | advanced

* Edit the file C:\ProgramData\VMware\vmnetdhcp.conf and add a segment at the end like:
N.B. this assumes NAT address - VMNet1 would be default for host-only

host VMnet1 {

    hardware ethernet _mac address of VM_;
    
    fixed-address _fixed IP address e.g. 192.168.141.132_;
    
    }
    

* stop and start the vmnet dhcp service:

```
net stop vmnetdhcp
net start vmnetdhcp
```

* Test the docker service from outside the VM using the fixed ip address (should not fail but will not return anything)

curl http://192.168.141.132:5000


## Installing on the OCP VM

### VM config

24 Gb RAM

8 cores

60 Gb hard disk
40 Gb nvme drive (for docker storage)

RHEL 7 + GUI + Development tools + System Admin tools, hostname ocp.example.com, user engineer

Host only connection in VMWare

NB may need to run dhclient on start up to force lease of (static) ip address

### Set up

 The below is based on steps from https://blog.openshift.com/openshift-all-in-one-aio-for-labs-and-fun/ while keeping one eye on https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-installing-openshift
 
 Steps follow:
 
* Add engineer to sudoers group
 
* Ensure Repo and Registry VMs are accessible (ping)

* Ensure _ifconfig_ resolves with static IP address - run _sudo dhclient_ if necessary

* add ip address and hostname (op.example.com) to /etc/hosts file

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

* Run prerequisites playbook

```
# ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
```

* the docker config file in /etc/sysconfig/docker needs to have an insecure registry added (this is removed by the prerequisites playbook) - the registry is the address of the registry VM

```
cat /etc/sysconfig/docker
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS=' --selinux-enabled     --insecure-registry=172.30.0.0/16 --insecure-registry=192.168.141.132:5000   --signature-verification=False'

[output redacted]
```

* A file needs to be created in /etc/origin/node/resolv.conf for the sdn pod to work correctly before running the deploy playbook

```
# echo "nameserver 192.168.141.1" > /etc/origin/node/resolv.conf
```

* Run the deploy playbook

```
# ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
```


* To uninstall and clean up:

```
# ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
```

### Deployment into OCP

* creating a deployable application is possible by directly referencng the images in the docker registry VM 

```
# docker pull 192.168.141.132:5000/openshift3/jenkins-2-rhel7:latest  # pull into local registry
# oc new-app --docker-image="192.168.141.132:5000/openshift3/jenkins-2-rhel7:latest"
```

After this add a PVC as the default is not persistent - this can be done via the console: delete the old pvc and add a new one
Ensure that the image pull policy in the deployment config is set to IfNotPresent (edit the dc)

```
# oc set volume dc/jenkins-2-rhel7 --remove --name=jenkins-2-rhel7-volume-1 # name of volume created
# edit dc jenkins-2-rhel7   # and set ImagePullPolicy to IfNotPresent
```
