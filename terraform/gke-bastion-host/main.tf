module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 10.0"

  region          = var.region
  project_id      = var.project_id
  network         = var.network
  service_account = var.service_account
  machine_type    = "e2-micro"
  source_image    = "debian-12-bookworm-v20240110"
  source_image_project  = "debian-cloud"
  source_image_family   = "debuain-12"
}

module "compute_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "~> 10.0"

  region              = var.region
  zone                = var.zone
  network             = var.network
  num_instances       = var.num_instances
  hostname            = "instance-simple"
  instance_template   = module.instance_template.self_link
  deletion_protection = false

  access_config = [{
    nat_ip       = var.nat_ip
    network_tier = var.network_tier
  }, ]

}
