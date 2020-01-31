docker save -o ose3-optional-images.tar \
    registry.redhat.io/openshift3/ose-efs-provisioner \
    registry.redhat.io/openshift3/metrics-cassandra \
    registry.redhat.io/openshift3/metrics-hawkular-metrics \
    registry.redhat.io/openshift3/metrics-hawkular-openshift-agent \
    registry.redhat.io/openshift3/metrics-heapster \
    registry.redhat.io/openshift3/metrics-schema-installer \
    registry.redhat.io/openshift3/oauth-proxy \
    registry.redhat.io/openshift3/ose-logging-curator5 \
    registry.redhat.io/openshift3/ose-logging-elasticsearch5 \
    registry.redhat.io/openshift3/ose-logging-eventrouter \
    registry.redhat.io/openshift3/ose-logging-fluentd \
    registry.redhat.io/openshift3/ose-logging-kibana5 \
    registry.redhat.io/openshift3/prometheus \
    registry.redhat.io/openshift3/prometheus-alertmanager \
    registry.redhat.io/openshift3/prometheus-node-exporter \
    registry.redhat.io/cloudforms46/cfme-openshift-postgresql \
    registry.redhat.io/cloudforms46/cfme-openshift-memcached \
    registry.redhat.io/cloudforms46/cfme-openshift-app-ui \
    registry.redhat.io/cloudforms46/cfme-openshift-app \
    registry.redhat.io/cloudforms46/cfme-openshift-embedded-ansible \
    registry.redhat.io/cloudforms46/cfme-openshift-httpd \
    registry.redhat.io/cloudforms46/cfme-httpd-configmap-generator \
    registry.redhat.io/rhgs3/rhgs-server-rhel7 \
    registry.redhat.io/rhgs3/rhgs-volmanager-rhel7 \
    registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7 \
    registry.redhat.io/rhgs3/rhgs-s3-server-rhel7