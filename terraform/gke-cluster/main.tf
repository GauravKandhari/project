module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project
  name                       = var.name
  region                     = var.region
  zones                      = var.zones
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  deletion_protection        = false

  node_pools = [
    {
      name            = "my-node-pool"
      machine_type    = "e2-medium"
      node_locations  = "europe-west1-b,europe-west1-c"
      min_count       = 1
      max_count       = 2
      local_ssd_count = 0
      spot            = false
      disk_size_gb    = 50
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      enable_gcfs     = false
      enable_gvnic    = false
      logging_variant = "DEFAULT"
      auto_repair     = true
      auto_upgrade    = true
      #service_account          = "gke-service-account@core-crowbar-232709.iam.gserviceaccount.com"
      preemptible = false
      #initial_node_count        = 80
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      my-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    my-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    my-node-pool = [
      {
        key    = "my-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    my-node-pool = [
      "my-node-pool",
    ]
  }
}
