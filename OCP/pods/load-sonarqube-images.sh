# log into the internal registry and push

oc login -u developer -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry.default.svc.cluster.local:5000


docker pull repo.thales.com:5000/sonarqube:7.4-community
docker pull repo.thales.com:5000/rhscl/postgresql-95-rhel7

docker tag repo.thales.com:5000/sonarqube:7.9-community docker-registry.default.svc.cluster.local:5000/openshift/sonarqube:7.4-community
docker tag repo.thales.com:5000/rhscl/postgresql-95-rhel7 docker-registry.default.svc.cluster.local:5000/openshift/postgresql-95-rhel7

docker push docker-registry.default.svc.cluster.local:5000/openshift/sonarqube:7.4-community
docker push  docker-registry.default.svc.cluster.local:5000/openshift/postgresql-95-rhel7

oc login -u system:admin
