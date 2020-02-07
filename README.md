# StackinaBox project

A project designed to create a development environment consisting of an IDE and an OpenShift cluster for deployment

Two runtime VMs will be created with one infra VM

IDE - containing an Eclipse development environment

OCP - containing an OpenShift cluster

Infra - for offline installation of OCP cluster containing RH repositories and image registries

Initial version will be manually provisioned. Later it will be scripted so that VMs can be provisioned automatically

RHEL will be used for production

![diagram](https://github.com/Estafet-LTD/StackinaBox/master/SIAB-infra-overview.png "VM connections")

## Pilot (see pilot-setup.md)

Initial pilot for OCP was manually configured using _oc cluster up_ but this was not easy to build disconnected

## Pilot 2 (see pilot-2-setup.md)

Second pilot was built entirely disconnected using openshift-ansible playbooks

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

### Infra VM
RHEL 7 VM (VMWare)
* Red Hat repos
* Required images
