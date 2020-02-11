# Set up the Repository and Registry VM

This VM will be used for the disconnected install and requires a connection to the internet to download Red Hat repositories and images

Requirements:

2Gb RAM

1 CPU

200Gb hard disk

NAT adapter for internet connection

Host only adapter for internal connection

root / rootpassw0rd

engineer / passw0rd

hostname: repo.thales.com

IP: 10.0.2.3

## Network setup

Set up the host only network by th efollowing:

* Update /etc/hosts file and add the following lines

```
10.0.2.1 ocp.thales.com
10.0.2.2 ide.thales.com
10.0.2.3 repo.thales.com
```

* Identify the network adapter for host only managed by VMWare (e.g. ens34)

* Edit the file at /etc/sysconfig/network-scripts/ifcfg-<adapter name>
    
 ```
# cat /etc/sysconfig/network-scripts/ifcfg-ens34
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
GATEWAY=10.0.2.3
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
IPADDR=10.0.2.3
PREFIX=24
PEERDNS=no
DNS1=10.0.2.3
```   

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

### Install HTTPD server

* Install httpd

```
$ yum install httpd
```

* Place repo files into apache's root folder

```
$ mv /OCP/repos /var/www/html/
$ chmod -R +r /var/www/html/repos
$ restorecon -vR /var/www/html
```

* Add firewall rules and restart
```
$ firewall-cmd --permanent --add-service=http
$ firewall-cmd --reload
```

* Enable and start Apache
```
$ systemctl enable httpd
$ systemctl start httpd
```

* Test connectivity to Apache from another VM
```
$ curl http://repo.thales.com # should respond with Apache main page
```
