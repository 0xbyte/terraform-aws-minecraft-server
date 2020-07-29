provider "aws" {
  region = "eu-west-2"
}

module "networking" {
  source = "./modules/networking"
  availability_zones = var.availability_zones
}

module "server" {
  source = "./modules/server"
  subnet_id = module.networking.subnet_ids[0]
  region = var.region
  availability_zone = var.availability_zones[0]
  vpc_id = module.networking.vpc_id
  s3_prefix_list_id = module.networking.s3_prefix_list_id
  mc_port = var.mc_port
  mc_root_directory = var.mc_root_directory
  mc_backup_freq = var.mc_backup_freq
  java_ms_mem = var.java_ms_mem
  java_mx_mem = var.java_mx_mem
  mc_jar_name = var.mc_jar_name
}

module "powerswitch" {
  source = "./modules/powerswitch"
  subnet_ids = module.networking.subnet_ids
  region = var.region
  vpc_id = module.networking.vpc_id
  server_instance_id = module.server.instance_id
  server_instance_arn = module.server.instance_arn
  hostname = var.power_switch_hostname
  hosted_zone_name = var.power_switch_hosted_zone_name
}
