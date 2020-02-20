# log into the internal registry and push

oc login -u deveoper -p developer

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry.default.svc.cluster.local:5000


docker pull repo.thales.com:5000/strimzi/operator:0.16.2
docker pull repo.thales.com:5000/strimzi/kafka-bridge:0.15.0
docker pull repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.4.0
docker pull repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.3.1

docker tag repo.thales.com:5000/strimzi/operator:0.16.2 docker-registry.default.svc.cluster.local:5000/strimzi/operator:0.16.2
docker tag repo.thales.com:5000/strimzi/kafka-bridge:0.15.0 docker-registry.default.svc.cluster.local:5000/strimzi/kafka-bridge:0.15.0
docker tag repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.4.0 docker-registry.default.svc.cluster.local:5000/strimzi/kafka:0.16.2-kafka-2.4.0
docker tag repo.thales.com:5000/strimzi/kafka:0.16.2-kafka-2.3.1 docker-registry.default.svc.cluster.local:5000/strimzi/kafka:0.16.2-kafka-2.3.1

docker push docker-registry.default.svc.cluster.local:5000/strimzi/operator:0.16.2
docker push docker-registry.default.svc.cluster.local:5000/strimzi/kafka-bridge:0.15.0
docker push docker-registry.default.svc.cluster.local:5000/strimzi/kafka:0.16.2-kafka-2.4.0
docker push docker-registry.default.svc.cluster.local:5000/strimzi/kafka:0.16.2-kafka-2.3.1

oc login -u system:admin