# log into the internal registry and push

oc login -u developer -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry-default.apps.ocp.thales.com


docker pull repo.thales.com:5000/clair-local-scan:v2.1.0
docker pull repo.thales.com:5000/clair-db:2020-03-19 # or whatever you have
docker pull repo.thales.com:5000/clair-scanner:v1.0

docker tag repo.thales.com:5000/clair-local-scan:v2.1.0 docker-registry-default.apps.ocp.thales.com/openshift/clair-local-scan:v2.1.0
docker tag repo.thales.com:5000/clair-db:2020-03-19 docker-registry-default.apps.ocp.thales.com/openshift/clair-db:2020-03-19
docker tag repo.thales.com:5000/clair-scanner:v1.0 docker-registry-default.apps.ocp.thales.com/openshift/clair-scanner:v1.0

docker push docker-registry-default.apps.ocp.thales.com/openshift/clair-local-scan:v2.1.0
docker push docker-registry-default.apps.ocp.thales.com/openshift/clair-db:2020-03-19
docker push docker-registry-default.apps.ocp.thales.com/openshift/clair-scanner:v1.0

oc login -u system:admin
