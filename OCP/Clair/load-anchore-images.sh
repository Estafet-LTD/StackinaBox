oc login -u developer -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry-default.apps.ocp.thales.com

docker pull repo.thales.com:5000/anchore/inline-scan:v0.4.0
docker tag repo.thales.com:5000/anchore/inline-scan:v0.4.0 docker-registry-default.apps.ocp.thales.com/openshift/anchore-inline-scan:v0.4.0
docker push docker-registry-default.apps.ocp.thales.com/openshift/anchore-inline-scan:v0.4.0

oc login -u system:admin
