docker pull docker.io/sonarqube:7.4-community
docker pull registry.redhat.io/rhscl/postgresql-95-rhel7

docker tag docker.io/sonarqube:7.4-community repo.thales.com:5000/sonarqube:7.4-community
docker tag registry.redhat.io/rhscl/postgresql-95-rhel7 repo.thales.com:5000/rhscl/postgresql-95-rhel7

docker push repo.thales.com:5000/sonarqube:7.4-community
docker push repo.thales.com:5000/rhscl/postgresql-95-rhel7
