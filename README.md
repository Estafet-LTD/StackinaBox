# StackinaBox project

A project designed to create a development environment consisting of an IDE and an OpenShift cluster for deployment

Two runtime VMs will be created with one infra VM

IDE - containing an Eclipse development environment
OCP - containing an OpenShift cluster

Infra - for offline installation of OCP cluster containing RH repositories and image registries

Initial version will be manually provisioned. Later it will be scripted so that VMs can be provisioned automatically

RHEL will be used for production

## Software to be included:

### IDE VM
RHEL 7 VM (VMWare)
* devtoolset
* git client
* maven
* Eclipse 2019-09

### OCP VM
RHEL 7 VM (VMWare) 
* OpenShift all-in-one cluster with Jenkins, SonarQube 
* Gitea 
* Nexus
