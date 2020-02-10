# Set up the repository and Registry VM

This VM will be used for the disconnected install and requires a connection to the internet to download Red Hat repositories and images

Requirements:

2Gb RAM

1 CPU

200Gb hard disk

NAT adapter for internet connection

Host only adapter for internal connection

root / rootpassw0rd

engineer / passw0rd

IP: 10.0.2.3  repo.thales.com

## Process

The process to follow is outlined at https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-repo-server - follow steps below:

### Sync the repositories

* To ensure that the packages are not deleted after you sync the repository, import the GPG key

```
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

* Register via subscription manager (enter username and password for RH account)

```
$ subscription-manager register
```

* Refresh subscription manager

```
$ subscription-manager refresh
```

* Find an available subscription pool that provides the OpenShift Container Platform channels

```
$ subscription-manager list --available --matches '*OpenShift*'
```

* Attach a pool id that has the correct subscriptions 

```
$ subscription-manager attach --pool=<pool id>
```

* Disable all repos 

```
$ subscription-manager repos --disable="*"
```

* Enable OpenShift repos 

```
$ subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.8-rpms"
```

* Install required packages, reate a directory for the repos

```
$ sudo yum -y install yum-utils createrepo docker git
$ mkdir -p /OCP/repos
```

* Sync and create all repos

```
$ for repo in \
rhel-7-server-rpms \
rhel-7-server-extras-rpms \
rhel-7-server-ansible-2.8-rpms \
rhel-7-server-ose-3.11-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=</OCP/repos> 
  createrepo -v </OCP/repos/>${repo} -o </OCP/repos/>${repo} 
done
```
