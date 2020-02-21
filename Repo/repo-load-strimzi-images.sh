docker pull registry-1.docker.io/strimzi/operator:0.16.2
docker pull registry-1.docker.io/strimzi/kafka-bridge:0.15.0
docker pull registry-1.docker.io/strimzi/kafka:0.16.2-kafka-2.4.0
docker pull registry-1.docker.io/strimzi/kafka:0.16.2-kafka-2.3.1

docker tag registry-1.docker.io/strimzi/operator:0.16.2 repo.thales.com:5000/strimzi/operator:0.16.2
docker tag registry-1.docker.io/strimzi/kafka-bridge:0.15.0 repo.thales.com:5000/strimzi/kafka-bridge:0.15.0
docker tag registry-1.docker.io/strimzi/kafka:0.16.2-kafka-2.4.0 repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.4.0
docker tag registry-1.docker.io/strimzi/kafka:0.16.2-kafka-2.3.1 repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.3.1

docker push repo.thales.com:5000/strimzi/operator:0.16.2
docker push repo.thales.com:5000/strimzi/kafka-bridge:0.15.0
docker push repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.4.0
docker push repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.3.1