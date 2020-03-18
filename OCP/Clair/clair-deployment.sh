# create sonarqube pods with persistent storage

# create storage folders for pv
mkdir /srv/nfs/clair
chown nfsnobody:nfsnobody /srv/nfs/clair -R
chmod 777 /srv/nfs/clair -R
echo "\"/srv/nfs/clair\" *(rw,root_squash)" >> /etc/exports.d/openshift-ansible.exports

systemctl restart nfs-server

echo "wait 10sec for nfs to restart"

sleep 10s

oc login -u system:admin

# create 3 persistent volumes for the sonarqube pods
oc create -f /home/engineer/ocp/pods/clair-pv.yaml

# pull sonarqube and postgres images from repo
source /home/engineer/ocp/pods/load-clair-images.sh

oc new-project clair

# create the template
oc apply -f /home/engineer/ocp/pods/clair-postgresql-template.yaml

# create the pods
oc new-app --template=clair
