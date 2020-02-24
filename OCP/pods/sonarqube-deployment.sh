# create sonarqube pods with persistent storage

# create storage folders for pv
mkdir /srv/nfs/sonarqube
chown nfsnobody:nfsnobody /srv/nfs/sonarqube -R
chmod 777 /srv/nfs/sonarqube -R
echo "\"/srv/nfs/sonarqube\" *(rw,root_squash)" >> /etc/exports.d/openshift-ansible.exports

systemctl restart nfs-server

echo "wait 10sec for nfs to restart"

sleep 10s

oc login -u system:admin

# create 3 persistent volumes for the sonarqube pods
oc create -f /home/engineer/ocp/pods/sonarqube-pv.yaml

# pull sonarqube and postgres images from repo
source /home/engineer/ocp/pods/load-sonarqube-images.sh

oc new-project sonarqube

# create the template
oc apply -f /home/engineer/ocp/pods/sonarqube-postgresql-template.yaml

# create the pods
oc new-app --template=sonarqube-postgresql
