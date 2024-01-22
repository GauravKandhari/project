We will use terrafrom as an Infrastructure as Code to deploy our cluster.

Prerequisite:
- Teeraform should be installed.


######################################################
GKE cluster creation on GCP
######################################################

-  cd '~/terraform/gke-cluster'
-  terraform init
-  terraform plan
-  terraform apply

Above commands will help you to create public GKE cluster.

######################################################
ArgoCD installation into public GKE cluster
######################################################

-   Connect to the GKE cluster created above using the below command
-   gcloud container clusters get-credentials gke-cluster-1 --region europe-west1 --project <Your-Project-ID>
-   Run command 'kubectl get ns' to check the connectivity to the cluster.
-   cd '~/argocd-helm'
-   Run the script 'argocd_installation.sh' to install argocd inside the cluster using helm and the creation of 'argocd' namespace.

######################################################
Private GKE cluster creation on GCP
######################################################

-  cd '~/terraform/gke-private-cluster'
-  terraform init
-  terraform plan
-  terraform apply
-  Get the cluster credentials
-  gcloud container clusters get-credentials test-private-cluster --region europe-west1 --project <Project-ID>

Above commands will help you to create private GKE cluster.



################################################################
Creation on Bastion host to connect with the private cluster
###############################################################

-  cd '~/terraform/gke-bastion-host'
-  terraform init
-  terraform plan
-  terraform apply
-  Once bastion host is ready, install tinyproxy
-  cd '~/terraform/gke-bastion-host/files'
-  ./script.sh    #This script will install tinyproxy and the port to connect is 8888

######################################################
Multi-Cluster management with ArgoCD
#####################################################

To achieve this we will be using 'secret' object within the argocd namespace created above in the public GKE
cluster. For this step workload identity should be enabled on the public GKE cluster, which is already done
in th efirst step.

-   Create a new serviceAccount in GCP with appropriate permissions for ArgoCD to manage multiple clusters.
	- Example: 'argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com

-   Assign appropriate permissions to ServiceAccount created above to acces multiple GKE clusters.
	-  Role: Kubernetes Engine Admin

-   Run below commands to enable kubernetes ServiceAccount to access Google Cloud ServiceAccount.
	-  gcloud iam service-accounts  add-iam-policy-binding argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser  --member "serviceAccount:<project_id>.svc.id.goog[argocd/argocd-server]"
        -  kubectl  annotate serviceaccount argocd-server --namespace argocd iam.gke.io/gcp-service-account=argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com
        -  gcloud iam service-accounts  add-iam-policy-binding argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser  --member "serviceAccount:<project_id>.svc.id.goog[argocd/argocd-application-controller]"
        -  kubectl  annotate serviceaccount argocd-application-controller --namespace argocd iam.gke.io/gcp-service-account=argocd-gke-cluster-management@<project_id>.iam.gserviceaccount.com

-   cd '~/argocd-helm'

-   kubectl apply -f test-private-cluster-secret.yaml


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

-    Connect to the public GKE cluster created above using the below command.
-    kubectl config use-context <public-gke-cluster-context>  #In '~/.kube/config' file.
-    git clone https://github.com/prometheus-operator/kube-prometheus.git
-    cd '~/kube-prometheus'
-    jb install
-    ./build.sh gke-cluster-1     #This will create all the yaml files related to kube prometheus stack
-    kubectl  apply --server-side -f clusters/gke-cluster-1/manifests/setup/
-    kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
-    kubectl apply -f clusters/gke-cluster-1/manifests/



#######################################################################
Deployment the application evmosd
######################################################################

Create a docker image using the documentation mentioned below.
URL: https://docs.evmos.org/protocol/evmos-cli/docker-build

-     After docker image creation push it to Artifact registry so that GKE clusters can pull the image from there.
-     Connect with the private GKE cluster
	-  kubectl config use-context <private-gke-cluster-context>  #In '~/.kube/config' file.
        -  Create the proxy using Bastion host
        -  gcloud compute ssh --tunnel-through-iap instance-simple-001 --zone=europe-west1-b --project=<Project-ID> --ssh-flag="-4 -L8888:localhost:8888 -N -q -f"
        -  export HTTPS_PROXY=localhost:8888
        -  kubectl get ns   #To check cluster connectivity

-     kubectl create ns evmos
-     cd '~/app/evmosd'
-     kubectl apply -f deployment.yaml
-     kubectl apply -f service.yaml
-     kubectl apply -f hpa.yaml


###############################################################################
Monitoring for the private GKE cluster and the applications in it.
###############################################################################

Release 0.13 is used for this project as it is compatible with GKE kubernetes version 1.27 which we are using.
Steps to install monitoring for private GKE cluster:

-    Connect to the private GKE cluster created above using the below command.
        -   kubectl config use-context <private-gke-cluster-context>  #In '~/.kube/config' file.
        -   Create the proxy using Bastion host
        -   gcloud compute ssh --tunnel-through-iap instance-simple-001 --zone=europe-west1-b --project=<Project-ID> --ssh-flag="-4 -L8888:localhost:8888 -N -q -f"
        -   export HTTPS_PROXY=localhost:8888
        -   kubectl get ns   #To check cluster connectivity
-    cd '~/kube-prometheus'
-    jb install
-    ./build.sh gke-private-cluster     #This will create all the yaml files related to kube prometheus stack
-    kubectl  apply --server-side -f clusters/gke-private-cluster/manifests/setup/
-    kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
-    kubectl apply -f clusters/gke-private-cluster/manifests/


############################################################################################################
Configuration to expose evmosd to the internet using Kubernetes gateway controller.
###########################################################################################################

Prerequisite:

- CRDs related to Gateway Controller need to be installed
  - kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
- Enable Gateway API on your config cluster
  - Update the terraform configuration to enable Gateway API for the cluster.
- Enable Workload Identity
  - Already enabled for the cluster
- Enable following API
  - container.googleapis.com
  - gkeconnect.googleapis.com
  - gkehub.googleapis.com
  - cloudresourcemanager.googleapis.com
- Enable the following multi-cluster Gateways required APIs in your project:
  - trafficdirector.googleapis.com
  - multiclusterservicediscovery.googleapis.com
  - multiclusteringress.googleapis.com

Useful Links:
- https://cloud.google.com/kubernetes-engine/docs/how-to/enabling-multi-cluster-gateways
- https://cloud.google.com/anthos/fleet-management/docs/before-you-begin#enable_apis
- https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-multi-cluster-gateways#external-gateway
- https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-api
- https://gateway-api.sigs.k8s.io/

Steps to install Gatway controller, TLS redirect, Routes related to application:

-   Connect to the private GKE cluster created above using the below command.
        -   kubectl config use-context <private-gke-cluster-context>  #In '~/.kube/config' file.
        -   Create the proxy using Bastion host
        -   gcloud compute ssh --tunnel-through-iap instance-simple-001 --zone=europe-west1-b --project=<Project-ID> --ssh-flag="-4 -L8888:localhost:8888 -N -q -f"
        -   export HTTPS_PROXY=localhost:8888
        -   kubectl get ns   #To check cluster connectivity
-   cd `~/gke-gateway-controller`
-   kubectl apply -f gateway-contoller.yaml
-   kubectl apply -f tls-redirect-route.yaml
-   kubectl apply -f gRPC-route.yaml

Currently, as no TLS certifate secret is present in the cluster so deployment of gateway controller (LB creation and IP allotment) will not happen.
Once certifate related configurations are present within the cluster, we can proceed with the above configurations.

For certificates we could use cert-manager: https://github.com/cert-manager/cert-manager



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
