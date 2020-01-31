# Set up for Pilot 2

Design for an all-in-one _disconnected_ install in the OpenShift VM requires another VM to contain the repositories

## Creation of the Repository VM

### VM config

4 Gb RAM

2 cores

140 Gb hard disk

NAT connection (for internet)

Host only connection (for local access)

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

### Fix the IP Address on th ehost only network
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

* Test the http server from outside the VM using the fixed ip address

curl http://192.168.141.132:5000


## Installing on the OCP VM

### VM config

24 Gb RAM

8 cores

80 Gb hard disk

Host only connection

### Set up

 Follow some steps from https://blog.openshift.com/openshift-all-in-one-aio-for-labs-and-fun/ while keeping one eye on https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-installing-openshift

* create ssh key

* add ip address and hostname to /etc/hosts file

* add default route

```
ip route add default via <ip address>
```

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

* Create an internal registry and import images from the Registry VM

* Create nfs storage in the VM - follow steps at https://www.thegeekdiary.com/centos-rhel-7-configuring-an-nfs-server-and-nfs-client/

* Install openshift using ansible

```
ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
```

* To uninstall and clean up:

```
ansible-playbook -i inventory_aio /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
```

### Workarounds

There is a need for one or two workarounds when running the all-in-one disconnected:

* The default route needs to be created for some internal elements of the OpenShift install

```
ip route add default via <ip address>
```

* A file needs to be created in /etc/origin/node/resolv.conf for the sdn pod to work correctly before running playbook

```
echo "nameserver 192.168.141.1" > /etc/origin/node/resolv.conf
```

* the docker config file in /etc/sysconfig/docker needs to have an insecure registry added (this is removed by the prerequisites playbook)

```
cat /etc/sysconfig/docker
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS=' --selinux-enabled     --insecure-registry=172.30.0.0/16 --insecure-registry=192.168.141.132:5000   --signature-verification=False'

[output redacted]
```

* creating a deployable application is possible by directly referencng the images in the docker registry VM 

```
oc new-app --docker-image="192.168.141.132:5000/openshift3/jenkins-2-rhel7:latest"
```

