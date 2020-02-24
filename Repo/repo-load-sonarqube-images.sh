docker pull docker.io/sonarqube:7.4-community
docker pull docker.io/postgres:9.5

docker tag docker.io/sonarqube:7.4-community repo.thales.com:5000/sonarqube:7.4-community
docker tag docker.io/postgres:9.5 repo.thales.com:5000/strimzi/postgres:9.5

docker push repo.thales.com:5000/sonarqube:7.4-community
docker push repo.thales.com:5000/postgres:9.5
