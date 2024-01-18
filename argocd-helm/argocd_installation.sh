#!/bin/bash

#Connect with the GKE cluster before running this script

kubectl create ns argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd

