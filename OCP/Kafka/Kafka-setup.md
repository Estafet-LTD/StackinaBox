# Setting up the kafka containers using strimzi

* Ensure files are in /home/engineer/ocp/pods:

```
kafka-pv.yaml
zoo-pv.yaml
kafka-deployment.sh
kafka-persistent-ocp-thales.yaml
load-strimzi-images.sh
050-deployment-strimzi-thales-ocp.yaml
```

* run the script to create folders, pv and pvc, project and pull the image

```
/home/engineer/ocp/pods/kafka-deployment.sh
```

#### smoke test kafka in container terminals

open two terminals on the kafka cluster pod that was created (e.g. my-cluster-kafka-0)

in the first terminal type the following. This will produce a command prompt (>) where you can type messages:

```
$ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic my-topic
```

in the second terminal type the following. This should echo the messages typed in the first terminal:

```
$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --from-beginning
```

Once these are open anything typed into the first, producer terminal will appear in the second, consumer terminal