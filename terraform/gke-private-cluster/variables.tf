variable "project_id" {
  type        = string
  description = "The project ID to deploy to"
}

variable "name" {
  type        = string
  description = "GKE cluster name."
}

variable "release_channel" {
  type        = string
  description = "GKE cluster name release channel."
}

variable "kubernetes_version" {
  type        = string
  description = "GKE master nodes version."
}

variable "region" {
  type        = string
  description = "GKE cluster region."
}

variable "network" {
  type        = string
  description = "Network in which GKE cluster will be created."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork in which GKE cluster will be created."
}

variable "registry_project_ids" {
  type        = list(string)
  default     = []
  description = "List of GCP Projects hosting GCR registries used in this GKE cluster. The ServiceAccount of this cluster would get read access to GCR on all these projects."
}
