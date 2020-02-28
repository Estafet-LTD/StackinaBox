# log into the internal registry and push

oc login -u deveoper -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry.default.svc.cluster.local:5000


docker pull repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift


docker tag repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift docker-registry.default.svc.cluster.local:5000/openshift/openjdk18-openshift

docker push docker-registry.default.svc.cluster.local:5000/openshift/openjdk18-openshift

oc login -u system:admin