# Setting up the Jenkins server in a container in the OpenShift cluster

This assumes that the OCP cluster has been successfully installed and that the **gitea** service is running

The following will explain the process to install Jenkins as a container within the cluster and the extra steps required to add plugins and configure

Note some steps require that other components have been installed (e.g. **Sonarqube**)

## Install the Jenkins pod

This wil install the Jenkins server in a container in the cluster with persistent volume

* Ensure these files are in /home/engineer/ocp/pods:

```
jenkins-pv.yaml
jenkins-pvc.yaml
jenkins-deployment.sh
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/jenkins-deployment.sh
```

## add extra plugins

The following plug-ins are assumed to be in the relevant folder of repo.thales.com. The versions cited are known to work with the version of Jenkins provided 

N.B. Some of these plugins will replace the defaults provided with the container - see below

| Plug-in | Version    | File name |
| ----- |------| --------- |
| maven    | 3.2 | maven-plugin.hpi |
| sonar scanner      | 2.8      |  sonar.hpi |
| jsch dependency | 0.1.54.2 | jch.hpi |
| gitea plugin | 1.2.0 | gitea.hpi |
| git plugin | 3.12.1 | git.hpi |
| git client | 2.7.7 | git-client.hpi |
| credentials | 2.3.0 | credentials.hpi |
| jackson2 api | 2.10.0 | jackson2-api.hpi |
| display url api | 2.3.2 | display-url-api.hpi |
| handy uri templates 2 | 2.1.8-1.0 | handy-uri-templates-2-api.hpi |


### get the plug-ins


```
wget http://repo.thales.com/jenkins-plugins/maven-plugin.hpi
wget http://repo.thales.com/jenkins-plugins/sonar.hpi
wget http://repo.thales.com/jenkins-plugins/jsch.hpi
wget http://repo.thales.com/jenkins-plugins/gitea.hpi
wget http://repo.thales.com/jenkins-plugins/git.hpi
wget http://repo.thales.com/jenkins-plugins/git-client.hpi
wget http://repo.thales.com/jenkins-plugins/credentials.hpi
wget http://repo.thales.com/jenkins-plugins/jackson2-api.hpi
wget http://repo.thales.com/jenkins-plugins/display-url-api.hpi
wget http://repo.thales.com/jenkins-plugins/handy-uri-templates-2-api.hpi
```

### get the maven tooling and put it in jenkins folder.

This assumes that the script above was run and the Jenkins persistent volume is at _/srv/nfs/jenkins_

```
mkdir /srv/nfs/jenkins/tools
mkdir /srv/nfs/jenkins/tools/M3
wget http://repo.thales.com/jenkins-plugins/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz --directory=/srv/nfs/jenkins/tools/M3
```

### move new plugins to jenkins folder

```
mv maven-plugin.hpi /srv/nfs/jenkins/plugins
mv sonar.hpi /srv/nfs/jenkins/plugins
mv jsch.hpi /srv/nfs/jenkins/plugins
mv gitea.hpi /srv/nfs/jenkins/plugins
mv git.hpi /srv/nfs/jenkins/plugins
mv git-client.hpi /srv/nfs/jenkins/plugins
mv credentials.hpi /srv/nfs/jenkins/plugins
mv jackson-2-api.hpi /srv/nfs/jenkins/plugins
mv display-url-api.hpi /srv/nfs/jenkins/plugins
mv handy-uri-templates-2-api.hpi /srv/nfs/jenkins/plugins
```

### remove old plugins

```
rm -rf /srv/nfs/jenkins/plugins/jsch # remove the old one
rm -rf /srv/nfs/jenkins/plugins/jsch.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/handy-uri-templates-2-api # remove the old one
rm -rf /srv/nfs/jenkins/plugins/handy-uri-templates-2-api.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/display-url-api # remove the old one
rm -rf /srv/nfs/jenkins/plugins/display-url-api.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/jackson-2-api # remove the old one
rm -rf /srv/nfs/jenkins/plugins/jackson-2-api.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/credentials # remove the old one
rm -rf /srv/nfs/jenkins/plugins/credentials.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/git # remove the old one
rm -rf /srv/nfs/jenkins/plugins/git.jpi # remove the old one
rm -rf /srv/nfs/jenkins/plugins/git-client # remove the old one
rm -rf /srv/nfs/jenkins/plugins/git-client.jpi # remove the old one
```

### bounce jenkins

```
oc rollout latest dc/jenkins-2-rhel7 -n=ci-cd
```


## configure Jenkins via console

### setup Gitea server for plug-in

In Manage Jenkins | Configure System | Gitea Servers | add server

name: gitea 

server url: http://ocp.thales.com:3000

check manage hooks

add engineer/Passw0rd! as credential

![diagram](https://github.com/Estafet-LTD/StackinaBox/blob/master/graphics/gitea%20server%20setup.jpg "Gitea server")

### setup Gitea organization

* In main menu, click "New Item".

* Select "Gitea organization" as the item type

* In the "Gitea organzations" section, add a new credential and choose the engineer/******** created earlier

* In the "Owner" field, add 'engineer'

Jenkins will scan the gitea repo and find engineer's projects 

Will automatically look to see if the project has a Jenkinsfile and check it out and try to build it - also creates a webhook in gitea


### set up Sonarqube  server  - see sonar setup.jpg

This assumes the Sonarqube server has already bee installed 

_In sonarqube console_ login as admin/admin [opt create a new user for jenkins] 

| My Account | Security | Generate Tokens | name it jenkins and copy it to clipboard

In the _Jenkins console_

| Manage Jenkins | Configure System | SonarQube Servers | add SonarQube

name: Sonar

server url: http://sonar-sonarqube.apps.ocp.thales.com 

server token: token copied from sonarqube 

![diagram](https://github.com/Estafet-LTD/StackinaBox/blob/master/graphics/sonar%20setup.jpg "Gitea server")

### maven tool

| Manage Jenkins | Global Tools Configuration | add Maven 

name: 'M3' 

maven home: /var/lib/jenkins/tools/M3/apache-maven-3.6.3/ [where the tool was untarred earlier]

### unload the maven repo into the jenkins folder

[replace these steps with the repo as required]

first zip /users/kevin/.m2/repository using 7zip (tar)

then gzip using 7zip

rename it maven-repository.tar.gz

put repository.tar.gz into SF and copy into repo at /var/www/html/maven

```
wget http://repo.thales.com/maven/maven-repository.tar.gz
tar xzf maven-repository.tar.gz --directory=/srv/nfs/jenkins/.m2 # this loads maven repo straight into jenkins filesystem
```
