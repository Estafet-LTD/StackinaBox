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

### Fix the IP Address
Find the mac address of the VM under VM settings | network adapter | advanced

* Edit the file C:\ProgramData\VMware\vmnetdhcp.conf and add a segment at the end like:
N.B. this assumes NAT address - VMNet1 would be default for host-only

host VMnet8 {
    hardware ethernet <mac address of VM>;
    fixed-address <fixed IP address e.g. 192.168.118.143>;
    }
* stop and start the vmnet dhcp service:

```
net stop vmnetdhcp
net start vmnetdhcp
```

* Test the http server from outside the VM using the fixed ip address

http://192.168.118.143

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
$ ./save-ocp-base-images.sh
$ ./save-ocp-opt-images.sh
$ ./save-ocp-s2i-images.sh
```


### Fix the IP Address
Find the mac address of the VM under VM settings | network adapter | advanced

* Edit the file C:\ProgramData\VMware\vmnetdhcp.conf and add a segment at the end like:
N.B. this assumes NAT address - VMNet1 would be default for host-only

host VMnet8 {
    hardware ethernet <mac address of VM>;
    fixed-address <fixed IP address e.g. 192.168.118.144>;
    }
* stop and start the vmnet dhcp service:

```
net stop vmnetdhcp
net start vmnetdhcp
```

* Test the http server from outside the VM using the fixed ip address

curl http://192.168.118.144:5000


## Installing on the OCP VM

### VM config

24 Gb RAM

8 cores

80 Gb hard disk

Host only connection

### Set up

* Install docker

* Load the docker images from shared folder

```
$ docker load -i ose3-images.tar
$ docker load -i ose3-builder-images.tar
$ docker load -i ose3-optional-images.tar
```



