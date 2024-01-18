We will use terrafrom as an Infrastructure as Code to deploy our cluster.

Prerequisite:
- Teeraform should be installed.


######################################################
GKE cluster creation on GCP
######################################################

i)   cd '~/terraform/gke-cluster'
ii)  terraform init
iii) terraform plan
iv)  terraform apply

Above commands will help you to create public GKE cluster.

######################################################
ArgoCD installation into public GKE cluster
######################################################

i)    Connect to the GKE cluster created above using the below command
ii)   gcloud container clusters get-credentials gke-cluster-1 --region europe-west1 --project <Your-Project-ID>
iii)  Run command 'kubectl get ns' to check the connectivity to the cluster.
iv)   cd '~/argocd-helm'
v)    Run the script 'argocd_installation.sh' to install argocd inside the cluster using helm and the creation of 'argocd' namespace.

######################################################
Private GKE cluster creation on GCP
######################################################

i)   cd '~/terraform/gke-private-cluster'
ii)  terraform init
iii) terraform plan
iv)  terraform apply
v)   Get the cluster credentials
vi)  gcloud container clusters get-credentials test-private-cluster --region europe-west1 --project <Project-ID>

Above commands will help you to create private GKE cluster.



################################################################
Creation on Bastion host to connect with the private cluster
###############################################################

i)   cd '~/terraform/gke-bastion-host'
ii)  terraform init
iii) terraform plan
iv)  terraform apply
v)   Once bastion host is ready, install tinyproxy
vi)  cd '~/terraform/gke-bastion-host/files'
vii) ./script.sh    #This script will install tinyproxy and the port to connect is 8888

######################################################
Multi-Cluster management with ArgoCD
#####################################################

To achieve this we will be using 'secret' object within the argocd namespace created above in the public GKE
cluster. For this step workload identity should be enabled on the public GKE cluster, which is already done
in th efirst step.

i)   Create a new serviceAccount in GCP with appropriate permissions for ArgoCD to manage multiple clusters.
	i) Example: 'argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com

ii)  Assign appropriate permissions to ServiceAccount created above to acces multiple GKE clusters.
	i) Role: Kubernetes Engine Admin

iii) Run below commands to enable kubernetes ServiceAccount to access Google Cloud ServiceAccount.
	i)   gcloud iam service-accounts  add-iam-policy-binding argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser  --member "serviceAccount:<project_id>.svc.id.goog[argocd/argocd-server]"
        ii)  kubectl  annotate serviceaccount argocd-server --namespace argocd iam.gke.io/gcp-service-account=argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com
        iii) gcloud iam service-accounts  add-iam-policy-binding argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser  --member "serviceAccount:<project_id>.svc.id.goog[argocd/argocd-application-controller]"
        iv)  kubectl  annotate serviceaccount argocd-application-controller --namespace argocd iam.gke.io/gcp-service-account=argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com

iv)  cd '~/argocd-helm'

v) kubectl apply -f test-private-cluster-secret.yaml


#############################################################
Monitoring setup
#############################################################

For monitoring we are using kube-prometheus/prometheus-operator stack.
URL: https://github.com/prometheus-operator/kube-prometheus

Prerequisite:
- Go
- gojsontoyaml
- jsonnet
- jb

Release 0.13 is used for this project as it is compatible with GKE kubernetes version 1.27 which we are using.
Steps to install monitoring for public GKE cluster:

i)    Connect to the public GKE cluster created above using the below command.
ii)   kubectl config use-context <public-gke-cluster-context>  #In '~/.kube/config' file.
iii)  git clone https://github.com/prometheus-operator/kube-prometheus.git
iii)  cd '~/kube-prometheus'
iv)   jb install
v)    ./build.sh gke-cluster-1     #This will create all the yaml files related to kube prometheus stack
vi)   kubectl  apply --server-side -f clusters/gke-cluster-1/manifests/setup/
vii)  kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
viii) kubectl apply -f clusters/gke-cluster-1/manifests/



#######################################################################
Deployment the application evmosd
######################################################################

Create a docker image using the documentation mentioned below.
URL: https://docs.evmos.org/protocol/evmos-cli/docker-build

i)    After docker image creation push it to Artifact registry so that GKE clusters can pull the image from there.
ii)   Connect with the private GKE cluster
	i)   kubectl config use-context <private-gke-cluster-context>  #In '~/.kube/config' file.
        ii)  Create the proxy using Bastion host
        iii) gcloud compute ssh --tunnel-through-iap instance-simple-001 --zone=europe-west1-b --project=<Project-ID> --ssh-flag="-4 -L8888:localhost:8888 -N -q -f"
        iv)  export HTTPS_PROXY=localhost:8888
        v)   kubectl get ns   #To check cluster connectivity

iv)   kubectl create ns evmos
iii)  cd '~/app/evmosd'
iv)   kubectl apply -f deployment.yaml
v)    kubectl apply -f service.yaml
vi)   kubectl apply -f hpa.yaml


###############################################################################
Monitoring for the private GKE cluster and the applications in it.
###############################################################################

Release 0.13 is used for this project as it is compatible with GKE kubernetes version 1.27 which we are using.
Steps to install monitoring for private GKE cluster:

i)    Connect to the private GKE cluster created above using the below command.
        i)   kubectl config use-context <private-gke-cluster-context>  #In '~/.kube/config' file.
        ii)  Create the proxy using Bastion host
        iii) gcloud compute ssh --tunnel-through-iap instance-simple-001 --zone=europe-west1-b --project=<Project-ID> --ssh-flag="-4 -L8888:localhost:8888 -N -q -f"
        iv)  export HTTPS_PROXY=localhost:8888
        v)   kubectl get ns   #To check cluster connectivity
iii)  cd '~/kube-prometheus'
iv)   jb install
v)    ./build.sh gke-private-cluster     #This will create all the yaml files related to kube prometheus stack
vi)   kubectl  apply --server-side -f clusters/gke-private-cluster/manifests/setup/
vii)  kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
viii) kubectl apply -f clusters/gke-private-cluster/manifests/




###############################################################################################
Ability to scale the solution to manage evmosd across multiple GKE clusters in the future.
###############################################################################################


With the above setup we can easily manage evmosd across multiple GKE clusters (Terraform for creation)
by adding more GKE clusters across regions.



#########################################################################
Justification for the selected IaC tools.
#########################################################################

Terraform is used mainly to tackle multi-cloud enviroment in the future
as terraform provides that functionality. In the end one tool to manage
different cloud environments.

Terraform can be easily integarted with CI tools as well.
