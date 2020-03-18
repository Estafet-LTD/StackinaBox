# log into the internal registry and push

oc login -u deveoper -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry-default.apps.ocp.thales.com


docker pull repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift


docker tag repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift docker-registry-default.apps.ocp.thales.com/openshift/openjdk18-openshift

docker push docker-registry-default.apps.ocp.thales.com/openshift/openjdk18-openshift

docker logout docker-registry-default.apps.ocp.thales.com

oc login -u system:admin