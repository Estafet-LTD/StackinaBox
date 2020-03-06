# Setting up the Sonarqube server in a container in the OpenShift cluster

This assumes that the OCP cluster has been successfully installed

The following will explain the process to install Sonarqube as a container within the cluster and the extra steps required to add plugins and configure

### Install Sonarqube pods and extra plugins

* Ensure files are in /home/engineer/ocp/pods:

```
load-sonarqube-images.sh
sonarqube-postgresql-template.yaml
sonarqube-deployment.sh
sonarqube-pv.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/sonarqube-deployment.sh
```

* Install plugins for sonarqube (example java plugin)

```
mkdir /srv/nfs/sonarqube/plugins # mkdir if this is first time
wget http://repo.thales.com/sonar-plugins/sonar-java-plugin-5.8.0.15699.jar # example for java
mv sonar-java-plugin-5.8.0.15699.jar /srv/nfs/sonarqube/plugins
oc rollout latest dc/sonar -n=sonarqube # redeploy the sonar pod for the plugin to be loaded
```