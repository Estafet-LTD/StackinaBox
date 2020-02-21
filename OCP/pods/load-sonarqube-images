# log into the internal registry and push

oc login -u deveoper -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry.default.svc.cluster.local:5000


docker pull repo.thales.com:5000/sonarqube:7.9-community
docker pull repo.thales.com:5000/postgres:9.5

docker tag repo.thales.com:5000/sonarqube:7.9-community docker-registry.default.svc.cluster.local:5000/openshift/sonarqube:7.9-community
docker tag repo.thales.com:5000/postgres:9.5 docker-registry.default.svc.cluster.local:5000/openshift/postgres:9.5

docker push docker-registry.default.svc.cluster.local:5000/openshift/sonarqube:7.9-community
docker push docker-registry.default.svc.cluster.local:5000/openshift/postgres:9.5

oc login -u system:admin