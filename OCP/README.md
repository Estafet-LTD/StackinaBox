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

## Install Kafka and associated products

### install strimzi

Follow instructions at https://strimzi.io/docs/latest/full.html#kafka-cluster-str (use _oc_ instead of _kubectl_ command)

Download latest strimzi release st https://github.com/strimzi/strimzi-kafka-operator/releases

Unzip release into a folder (e.g. strimzi-0.15.0)

```
$ oc new-project kafka
$ cd strimzi-0.15.0
$ oc apply -f install/cluster-operator/
$ oc edit scc restricted # add lines  
# fsGroup:
# type: RunAsAny
```

if deployment fails with "no RBAC policy matched"

```
$	oc adm policy add-cluster-role-to-user strimzi-cluster-operator-namespaced --serviceaccount strimzi-cluster-operator -n <project>
```

delete failing pod and redeploy from deployment

### install kafka cluster

add persistent kafka cluster called my-cluster and a topic called my-topic using the example yaml files:

```
$ oc apply -f examples/kafka/kafka-persistent-single.yaml
$ oc apply -f examples/topic/kafka-topic.yaml
```

#### smoke test kafka in container terminals

open two terminals on the kafka cluster pod that was created (e.g. my-cluster-kafka-0)

in the first terminal type the following. This will produce a command prompt (>) where you can type messages:

```
$ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-topic
```

in the second terminal type the following. This should echo the messages typed in the first terminal:

```
$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --from-beginning
```

Once these are open anything typed into the first, producer terminal will appear in the second, consumer terminal

It seems that there is some configuration that happens first time the producer is run so it may need to be run twice to work properly

To prove that this is a topic that persists the messages try shutting down the consumer and re-running it. All messages from the start should be displayed. This should also survive a VM restart as it is held in a persistent volume

## GITEA [automate later]
Follow instructions at https://computingforgeeks.com/how-to-install-gitea-self-hosted-git-service-on-centos-7-with-nginx-reverse-proxy/

## Considerations when setting up a pipeline for java applications

### The default user in the ci-cd project requires admin rights to a project to perform the OpenShift DSL pipeline steps as this will be used by Jenkins.

The following extra set up is required (for example project):

```
$ oc new-project example
$ oc policy add-role-to-user admin system:serviceaccount:ci-cd:default
```

### Need to create a spring-boot builder image that can be retained in the OpenShift docker registry

Note tried to use the Red Hat openjdk18 s2i image but this kept wanting to connect to RH access

Eventually built a s2i image from https://github.com/ganrad/openshift-s2i-springboot-java

The following steps will create a spring-boot builder image stream in the project (maybe consider doing this in the openshift project in future)

```
$ oc login

$ oc project example-project

$ oc new-build --strategy=docker --name=springboot-java https://github.com/ganrad/openshift-s2i-springboot-java.git
```

Note: this fails as the image will not find an acceptable version of maven so after the first image fails:

Go to OpenShift console:

in example-project
* under builds | builds
* Select springboot-java
* Under environment add MAVEN_VER = 3.0.5, GRADLE_VER = 4.4, Save and Start Build
* This time build should succeed and push the new s2i image to the registry
