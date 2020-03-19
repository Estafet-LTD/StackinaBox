# Setting up Clair in the OpenShift cluster for vulnerability scanning

In order to use Clair as a disconnected vulnerability scanner there are several steps to follow:

*  Get a snapshot image of the Clair database into the Infrastructure VM

*  Get the Clair server image into the Infrastructure VM

*  Get the Clair scanner image into the Infrastructure VM

*  Set up the containers in the OCP cluster

*  Add a further scanner container to liaise with Clair server (e.g. Klar) 

*  Add a step to the CI/CD Pipeline to invoke the scanner container

## Getting latest updates for Clair vulnerabilities

Because Clair by default wants to be connected to the internet so that it can download lists of vulnerabilities on a regular basis (think virus checker) running Clair disconnected of necessity means you are running with a snapshot of vulnerabilities

There is a version of the Clair database made available with a job that updates it regularly on the docker hub - arminc/clair-db. This can be pulled as and when required into the Infra VM and from there to the OCP VM

``` 
docker pull docker.io/arminc/clair-db:2020-03-19
docker tag docker.io/arminc/clair-db:2020-03-19 repo.thales.com:5000/clair-db:2020-03-19
docker push repo.thales.com:5000/clair-db:2020-03-19
```


## Installing the images in the OCP VM

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