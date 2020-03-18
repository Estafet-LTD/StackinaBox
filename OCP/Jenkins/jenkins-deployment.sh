# create jenkins pod with persistent storage

# create storage folders for pv
mkdir /srv/nfs/jenkins
chown nfsnobody:nfsnobody /srv/nfs/jenkins -R
chmod 777 /srv/nfs/jenkins -R
echo "\"/srv/nfs/jenkins\" *(rw,root_squash)" >> /etc/exports.d/openshift-ansible.exports

systemctl restart nfs-server

echo "wait 10sec for nfs to restart"

sleep 10s

# login as admin
oc login -u system:admin

# create a persistent volume
oc create -f /home/engineer/ocp/pods/jenkins-pv.yaml

# login as developer
oc login -u developer -p developer

# pull jenkins image into openshift project
oc project openshift

docker pull repo.thales.com:5000/openshift3/jenkins-2-rhel7

docker tag repo.thales.com:5000/openshift3/jenkins-2-rhel7 docker-registry-default.apps.ocp.thales.com/openshift/jenkins-2-rhel7

# log into the internal registry and push

TOKEN=$(oc whoami -t)

docker login -u developer -p $TOKEN docker-registry.default.svc.cluster.local:5000

docker push docker-registry-default.apps.ocp.thales.com/openshift/jenkins-2-rhel7

# create ci project

oc new-project ci-cd

oc new-app openshift/jenkins-2-rhel7:latest

# create a persistent volume claim
oc create -f /home/engineer/ocp/pods/jenkins-pvc.yaml

# give the jenkins sa full access
oc policy add-role-to-user admin system:serviceaccount:ci-cd:default

# remove the default pvc and replace with the jenkins-claim
oc set volume dc/jenkins-2-rhel7 --remove --name=jenkins-2-rhel7-volume-1
oc set volume dc/jenkins-2-rhel7 --add --mount-path=/var/lib/jenkins -t pvc --claim-name=jenkins-claim

# create a route to the jenkins service
oc expose service jenkins-2-rhel7 --name=jenkins-route --hostname=jenkins.ocp.thales.com
