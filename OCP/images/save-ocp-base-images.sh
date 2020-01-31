docker save -o ose3-images.tar \
    registry.redhat.io/openshift3/apb-base \
    registry.redhat.io/openshift3/apb-tools \
    registry.redhat.io/openshift3/automation-broker-apb \
    registry.redhat.io/openshift3/csi-attacher \
    registry.redhat.io/openshift3/csi-driver-registrar \
    registry.redhat.io/openshift3/csi-livenessprobe \
    registry.redhat.io/openshift3/csi-provisioner \
    registry.redhat.io/openshift3/grafana \
    registry.redhat.io/openshift3/local-storage-provisioner \
    registry.redhat.io/openshift3/manila-provisioner \
    registry.redhat.io/openshift3/mariadb-apb \
    registry.redhat.io/openshift3/mediawiki \
    registry.redhat.io/openshift3/mediawiki-apb \
    registry.redhat.io/openshift3/mysql-apb \
    registry.redhat.io/openshift3/ose-ansible-service-broker \
    registry.redhat.io/openshift3/ose-cli \
    registry.redhat.io/openshift3/ose-cluster-autoscaler \
    registry.redhat.io/openshift3/ose-cluster-capacity \
    registry.redhat.io/openshift3/ose-cluster-monitoring-operator \
    registry.redhat.io/openshift3/ose-console \
    registry.redhat.io/openshift3/ose-configmap-reloader \
    registry.redhat.io/openshift3/ose-control-plane \
    registry.redhat.io/openshift3/ose-deployer \
    registry.redhat.io/openshift3/ose-descheduler \
    registry.redhat.io/openshift3/ose-docker-builder \
    registry.redhat.io/openshift3/ose-docker-registry \
    registry.redhat.io/openshift3/ose-efs-provisioner \
    registry.redhat.io/openshift3/ose-egress-dns-proxy \
    registry.redhat.io/openshift3/ose-egress-http-proxy \
    registry.redhat.io/openshift3/ose-egress-router \
    registry.redhat.io/openshift3/ose-haproxy-router \
    registry.redhat.io/openshift3/ose-hyperkube \
    registry.redhat.io/openshift3/ose-hypershift \
    registry.redhat.io/openshift3/ose-keepalived-ipfailover \
    registry.redhat.io/openshift3/ose-kube-rbac-proxy \
    registry.redhat.io/openshift3/ose-kube-state-metrics \
    registry.redhat.io/openshift3/ose-metrics-server \
    registry.redhat.io/openshift3/ose-node \
    registry.redhat.io/openshift3/ose-node-problem-detector \
    registry.redhat.io/openshift3/ose-operator-lifecycle-manager \
    registry.redhat.io/openshift3/ose-ovn-kubernetes \
    registry.redhat.io/openshift3/ose-pod \
    registry.redhat.io/openshift3/ose-prometheus-config-reloader \
    registry.redhat.io/openshift3/ose-prometheus-operator \
    registry.redhat.io/openshift3/ose-recycler \
    registry.redhat.io/openshift3/ose-service-catalog \
    registry.redhat.io/openshift3/ose-template-service-broker \
    registry.redhat.io/openshift3/ose-tests \
    registry.redhat.io/openshift3/ose-web-console \
    registry.redhat.io/openshift3/postgresql-apb \
    registry.redhat.io/openshift3/registry-console \
    registry.redhat.io/openshift3/snapshot-controller \
    registry.redhat.io/openshift3/snapshot-provisioner \
    registry.redhat.io/rhel7/etcd:3.2.22