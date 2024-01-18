module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 29.0"

  project_id                        = var.project_id
  name                              = var.name
  release_channel                   = var.release_channel
  kubernetes_version                = var.kubernetes_version
  region                            = var.region
  regional                          = true
  network                           = var.network
  subnetwork                        = var.subnetwork
  ip_range_pods                     = ""
  ip_range_services                 = ""
  enable_private_endpoint           = true
  enable_private_nodes              = true
  master_ipv4_cidr_block            = "172.16.0.16/28"
  network_policy                    = true
  horizontal_pod_autoscaling        = true
  service_account                   = "create" # We can create our own SeviceAccount as well with limited permissions.
  remove_default_node_pool          = true
  disable_legacy_metadata_endpoints = true
  deletion_protection               = false
  grant_registry_access             = true # To pull images from registry. evmosd docker image is in the Artifact registry.
  registry_project_ids              = var.registry_project_ids

  master_authorized_networks = [
    {
      cidr_block   = "10.132.0.0/20"
      display_name = "VPC"
    },
  ]

  node_pools = [
    {
      name                = "my-node-pool"
      machine_type        = "n1-standard-2"
      node_pools_versions = "1.27.3-gke.100"
      min_count           = 1
      max_count           = 1
      disk_size_gb        = 50
      disk_type           = "pd-ssd"
      auto_repair         = true
      auto_upgrade        = true
      preemptible         = false
      initial_node_count  = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
    ]

    my-node-pool = [
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
  }

  node_pools_labels = {

    all = {

    }
    my-node-pool = {

    }
  }

  node_pools_metadata = {
    all = {}

    my-node-pool = {}

  }

  node_pools_tags = {
    all = []

    my-node-pool = []

  }
}
