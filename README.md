# StackinaBox project

A project designed to create a development environment consisting of an IDE and an OpenShift cluster for deployment

Two VMs will be created:

IDE - containing an Eclipse development environment
OCP - containing an OpenShift cluster

Initial version will be manually provisioned. Later it will be scripted so that VMs can be provisioned automatically

Currently Centos 7 is used but RHEL will be used for production

## Software to be included:

### IDE VM
Centos7 VM (VMWare)
* devtoolset
* git client
* maven
* Eclipse 2019-09

### OCP VM
Centos7 VM (VMWare) 
* OpenShift all-in-one cluster with Jenkins, SonarQube
* Gitea 