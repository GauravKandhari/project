variable "project" {
  type        = string
  description = "GCP Project hosting this GKE cluster."
}

variable "name" {
  type        = string
  description = "GKE cluster name."
}

variable "region" {
  type        = string
  description = "GCP Region hosting this GKE cluster."
}

variable "zones" {
  type        = list(string)
  description = "List of GCP zones hosting this GKE cluster and its node pools."
}

variable "network" {
  type        = string
  description = "Network in which GKE cluster will be created."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork in which GKE cluster will be created."
}
