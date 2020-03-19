# Setting up Clair in the OpenShift cluster for vulnerability scanning

This assumes that the OCP cluster has been successfully installed

The following will explain the process to install Clair and its database as containers within the cluster and the extra steps required to configure it for use in a CI/Cd pipeline

## Setting up the Clair server and database in containers in the OpenShift cluster

Note this requires that the postgresql-95-rhel7 image stream has already been installed **(This image is installed as part of Sonarqube)**

### Install the Clair pods

This will install the Clair server and a Postgres DB container in the cluster with a persistent volume


* Ensure files are in /home/engineer/ocp/pods:

```
load-clair-images.sh
clair-postgresql-template.yaml
clair-deployment.sh
clair-pv.yaml
```

* run the script to pull the image then create folders, pv, project, and template

```
/home/engineer/ocp/pods/clair-deployment.sh
```

### add extra configuration

TO-DO