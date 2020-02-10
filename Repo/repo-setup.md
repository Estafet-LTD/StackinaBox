# Set up the repository and Registry VM

This VM will be used for the disconnected install and requires a connection to the internet to download Red Hat repositories and images

Requirements:

2Gb RAM

1 CPU

200Gb hard disk

NAT adapter for internet connection

Host only adapter for internal connection

## Process

The process to follow is outlined at https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-repo-server - follow steps below:

### Sync the repositories

* To ensure that the packages are not deleted after you sync the repository, import the GPG key





