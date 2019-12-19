Following instructions at https://github.com/openshift/origin/blob/release-3.11/docs/cluster_up_down.md

# Docker
[a install docker]

```
$ sudo yum install docker
```
[b set up insecure registries for docker daemon]

```
$ sudo vi /etc/containers/registries.conf
Under [registries.insecure] add registries = ['172.30.0.0/16']
OR add to /etc/docker/daemon.json:
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

[f create a new firewalld zone for the subnet and grant it access to the API and DNS ports]

```
$ firewall-cmd --permanent --new-zone dockerc
$ firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
$ firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
$ firewall-cmd --permanent --zone dockerc --add-port 53/udp
$ firewall-cmd --permanent --zone dockerc --add-port 8053/udp
$ firewall-cmd --reload
```

# OpenShift CLI (oc)

extract oc 3.11 and add to path in .bash_profile

```
# source ~/.bash_profile
```

```
$ systemctl restart docker
$ oc cluster up --public-hostname=[ip address host network]

$ oc new project ci-cd 
```



### JENKINS [needs to be automated with ansible galaxy OpenShift Applier] 

```
$ oc new-app jenkins
```
After deploy login as admin/password

Added persistent volume to Jenkins manually including mount point /var/lib/jenkins (triggered redeploy)

Removed default pvc (empty dir) (triggered redeploy) 

Smoke tested with hello-world job - persisted beyond cluster down

## GITEA [automate later]
