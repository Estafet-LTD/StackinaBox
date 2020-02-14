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

* Enable OpenShift repos **NB the build asks for Ansible 2.8 but there are issues (see OCP-setup) so Ansible 2.6 was used**

```
$ subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.8-rpms" # --enable="rhel-7-server-ansible-2.6-rpms"
```

* Install required packages, create a directory for the repos

```
$ sudo yum -y install yum-utils createrepo docker git
$ mkdir -p /OCP/repos
```

* Sync and create all repos

```
$ for repo in \
rhel-7-server-rpms \
rhel-7-server-extras-rpms \
rhel-7-server-ansible-2.8-rpms \ # rhel-7-server-ansible-2.6-rpms
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

### Set up Docker

* enable and start Docker

```
$ systemctl enable docker
$ systemctl start docker
```

* generate a new self-signed certificate for the secure Docker registry

```
$ openssl req -newkey rsa:4096 -nodes -sha256 -keyout /etc/ssl/certs/registry.key -x509 -days 1825 -out /etc/ssl/certs/registry.crt
# Fill out the various requirements such as country code etc as appropriate
```

* Disable SELinux

When SELinux is **enforcing** the docker registry has permission issues around reading the certificates

Edit the /etc/selinux/config file and set SELINUX=disabled. 

Reboot

* Start secure docker registry with basic authentication

```
$ mkdir docker-certs
$ cp -a /etc/ssl/certs/. docker-certs
$ mkdir auth
$ docker run --entrypoint htpasswd registry:2 -Bbn engineer passw0rd > auth/htpasswd 
$ docker run -d -p 5000:5000 --restart=always --name registry -v "$(pwd)"/auth:/auth -e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd -v "$(pwd)"/docker-certs:/certs \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key registry:2
```

### Load, tag, and push images into the Docker registry

* Pull the required docker images into the registry using the scripts:

```
$ ./pull-ocp-base-images.sh
$ ./pull-ocp-opt-images.sh
$ ./pull-ocp-s2i-images.sh
```

* OPTIONAL Save the required docker images into tar files on the shared folder using the scripts NB this will not be necessary if the registry server is connected and there is no need for the registry to be held elsewhere

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

$ cd /mnt/hgfs/SF #  shared folder
$ ./push-ocp-base-images.sh
$ ./push-ocp-opt-images.sh
$ ./push-ocp-s2i-images.sh
```

### Download gitea binaries

* Pull gitea 1.11.0 into repo VM

```
$ yum install wget

$ wget -O gitea https://dl.gitea.io/gitea/1.11.0/gitea-1.11.0-linux-amd64
$ mkdir /var/www/html/gitea
$ mv gitea /var/www/html/gitea
```
