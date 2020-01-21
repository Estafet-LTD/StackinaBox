# Set up for Pilot 2

Design for an all-in-one _disconnected_ install in the OpenShift VM requires another VM to contain the repositories

## Creation of the Repository VM

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

* Save the required docker images locally into tar files using the scripts:

```
$ cd /<image directory>
$ ./save-ocp-base-images.sh
$ ./save-ocp-opt-images.sh
$ ./save-ocp-s2i-images.sh
$ cp ose3-builder-images.tar ose3-optional-imags.tar ose3-images.tar /mnt/hgfs/SF # export to shared folder
```

## Installing on the OCP VM

* Load the docker images from shared folder

```
$ docker load -i ose3-images.tar
$ docker load -i ose3-builder-images.tar
$ docker load -i ose3-optional-images.tar
```



