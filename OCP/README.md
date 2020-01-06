Following instructions at https://github.com/openshift/origin/blob/release-3.11/docs/cluster_up_down.md

# Docker
[a install docker]
If another app (PackageKit) is holding yum lock then

```
 $ pkill PackageKit
 ```

```
$ sudo yum install docker
```
[b set up insecure registries for docker daemon]

```
$ sudo vi /etc/docker/daemon.json
and add:
{
        "insecure-registries" : ["172.30.0.0/16"]
    }
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```
[c ensure user has permissions for docker daemon]

```
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ sudo chmod 666 /var/run/docker.sock
```
[d show that docker daemon is running and accessible]

```
$ docker version 
Version:         1.13.1
 API version:     1.26
 Package version: docker-1.13.1-103.git7f2769b.el7.centos.x86_64
 Go version:      go1.10.3
 Git commit:      7f2769b/1.13.1
 Built:           Sun Sep 15 14:06:47 2019
 OS/Arch:         linux/amd64

Server:
 Version:         1.13.1
 API version:     1.26 (minimum version 1.12)
 Package version: docker-1.13.1-103.git7f2769b.el7.centos.x86_64
 Go version:      go1.10.3
 Git commit:      7f2769b/1.13.1
 Built:           Sun Sep 15 14:06:47 2019
 OS/Arch:         linux/amd64
 Experimental:    false
 ```
[e find docker bridge subnet]

```
$ docker network inspect -f "{{range .IPAM.Config }}{{ .Subnet }}{{end}}" bridge
172.17.0.0/16
```

# opening firewalls
[a create a new firewalld zone for the subnet and grant it access to the API and DNS ports]

```
$ firewall-cmd --permanent --new-zone dockerc
$ firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
$ firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
$ firewall-cmd --permanent --zone dockerc --add-port 53/udp
$ firewall-cmd --permanent --zone dockerc --add-port 8053/udp
$ firewall-cmd --reload
```
[b open Windows Defender firewall for the VM adapter]

Windows Firewall | Advanced Settings | Windows Defender Firewall Properties | Protected Network Connections | Uncheck the correct VMWare Network Adapter

[c open VM firewall to outside]

```
$ firewall-cmd --permanent --add-port=8443/tcp
$ firewall-cmd --permanent --add-port=80/tcp
$ firewall-cmd --permanent --add-port=443/tcp
$ firewall-cmd --permanent --add-port=3000/tcp # used by gitea
$ firewall-cmd --permanent --add-port=9000/tcp # used by sonarqube
$ firewall-cmd --reload
```

# OpenShift CLI (oc)

extract oc 3.11 and add to path in .bash_profile

```
# source ~/.bash_profile
```

# Fix the IP Address
Find the mac address of the VM under VM settings | network adapter | advanced

Edit the file C:\ProgramData\VMware\vmnetdhcp.conf and add a segment at the end like:
N.B. this assumes NAT address - VMNet1 would be default for host-only

host VMnet8 {
    hardware ethernet <mac address of VM>;
    fixed-address <fixed IP address e.g. 192.168.118.130>;
    }
    
stop and start the vmnet dhcp service:

```
net stop vmnetdhcp
net start vmnetdhcp
```


# OpenShift Cluster 

## start the cluster 

use the fixed ip address set above [perhaps 192.168.x.x]

call _oc cluster up_ with --public-hostname=[ip address] 

check that console is available from outside the VM

## controlling the OpenShift cluster

Use _oc cluster down_ to stop the cluster - it should use permanent storage to remember its state

When restarting the cluster:

```
$ systemctl start docker
$ oc cluster up --public-hostname=[ip address]
```



### Install Jenkins 

[needs to be automated with ansible galaxy OpenShift Applier in due course] 

```
$ oc new project ci-cd 
$ oc new-app jenkins
```

Add a persistent volume claim (pvc) to jenkins via Storage menu option named _jenkins-pvc_ - this will automatically be bound to one of the pvs created by the cluster

Remove default pvc (_empty dir_) created by the new-app command (this will trigger a redeploy)

```
$ oc set volume dc/jenkins --remove --name=jenkins-volume-1 # name of volume created
```

Add a new persistent volume to Jenkins manually (_add storage to jenkins_ on pod details page)including mount point /var/lib/jenkins and referring to the pvc created earlier (this will trigger a redeploy)

Add a route to expose the jenkins service with hostname jenkins.192.168.x.x.nip.io [ip address of cluster]

Check that jenkins can be accessed from within and outside the vm

After deploy can login to Jenkins as admin/password

Smoke tested with hello-world job - persisted beyond cluster down

### Install SonarQube

[automate in due course]

Create a new project called sonarqube

Follow the instructions at https://medium.com/@dale.bingham_30375/setup-sonarqube-in-minishift-for-scanning-projects-through-jenkins-a70a6e2d93d3

In addition log into the SonarQube console as admin and install the SonarJava Quality Profile via Administration | Marketplace and allow the SonarQube server to rebuild

Create a user named jenkins and a token for the user - see https://docs.sonarqube.org/latest/user-guide/user-token/

### Configure Jenkins

In Manage Jenkins | Global Tools Configuration | add Maven - name it 'M3' - select the default download option

In Manage Jenkins | Global Tools Configuration | add Docker - name it 'Docker' - select the default donload option

In Manage Jenkins |Manage Plugins | add Sonarqube plugin and allow rebuild

In Manage Jenkins | Global Tools Configuration | add SonarQube Scanner - name it 'Sonar' - select the default donload option

In Manage Jenkins | Configure System - under SonarQube section tick the box Enable injection of SonarQube server configuration as build environment variables and fill in server details - note the url for the server should be the internal one (ending in .svc). Also add the credential which will be the token created by SonarQube. Use type secret text and name it e.g. sq-token


## GITEA [automate later]
Follow instructions at https://computingforgeeks.com/how-to-install-gitea-self-hosted-git-service-on-centos-7-with-nginx-reverse-proxy/
