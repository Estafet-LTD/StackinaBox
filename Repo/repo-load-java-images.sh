docker pull registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift
docker tag registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift
docker push repo.thales.com:5000/redhat-openjdk-18/openjdk18-openshift