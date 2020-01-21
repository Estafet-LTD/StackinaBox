# Set up for Pilot 2

Design for an all-in-one _disconnected_ install in the OpenShift VM requires another VM to contain the repositories

## Creation of the Repository VM

This VM can be created with an internet connection as long as the OCP VM is disconnected

This VM will act as the Repository server when installing OCP in the OCP VM and also hold the registry of required images which will be saved to tars and made available to the OCP via shared folders

Follow basic instructions at https://docs.openshift.com/container-platform/3.11/install/disconnected_install.html#disconnected-repo-server
with basic steps as follows:

* Obtain the required Red Hat repositories

