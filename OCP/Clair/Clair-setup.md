# Setting up the Clair server in a container in the OpenShift cluster

This assumes that the OCP cluster has been successfully installed

The following will explain the process to install Clair and its database as containers within the cluster and the extra steps required to configure

Note some steps require that other components have been installed (e.g. **Postgres image installed as part of Sonarqube**)

## Install the Clair pods

This will install the Clair server and a Postgres db in containers in the cluster with a persistent volume

* Ensure these files are in /home/engineer/ocp/pods:

### Install Clair pods

* Ensure files are in /home/engineer/ocp/pods:

```
load-clair-images.sh
clair-postgresql-template.yaml
clair-deployment.sh
clair-pv.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/clair-deployment.sh
```

## add extra configuration

TO-DO