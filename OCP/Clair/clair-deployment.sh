# pull clairimages from repo
source /home/engineer/ocp/pods/load-clair-images.sh

oc new-project clair


# clair-db wants to run as root so permit it
oc adm policy add-scc-to-user anyuid -z default

oc new-app -i openshift/clair-db:2020-03-19

oc new-app -i openshift/clair-local-scan:v2.1.0

# create the template
oc apply -f /home/engineer/ocp/pods/clair-template.yaml

# create the pods
oc new-app --template=clair

