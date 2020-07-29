provider "aws" {
  region = "eu-west-2"
}

module "networking" {
  source = "./modules/networking"
  availability_zone = var.availability_zone
}

module "server" {
  source = "./modules/server"
  subnet_id = module.networking.subnet_id
  region = var.region
  availability_zone = var.availability_zone
  vpc_id = module.networking.vpc_id
  s3_prefix_list_id = module.networking.s3_prefix_list_id
  mc_port = var.mc_port
  mc_root_directory = var.mc_root_directory
  mc_backup_freq = var.mc_backup_freq
  java_ms_mem = var.java_ms_mem
  java_mx_mem = var.java_mx_mem
}
