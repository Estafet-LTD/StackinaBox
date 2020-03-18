# log into the internal registry and push

oc login -u developer -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry-default.apps.ocp.thales.com


docker pull repo.thales.com:5000/clair:v2.0.8

docker tag repo.thales.com:5000/clair:v2.0.8 docker-registry-default.apps.ocp.thales.com/openshift/clair:v2.0.8

docker push docker-registry-default.apps.ocp.thales.com/openshift/clair:v2.0.8

oc login -u system:admin
