module "network_label" {
  source = "cloudposse/label/null"
  version = "0.16.0"
  namespace = "minecraft"
  name = "network"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Networking"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.44.0"
  name = module.network_label.id
  cidr = "10.0.0.0/16"
  azs = var.availability_zones
  private_subnets = []
  public_subnets = [
    "10.0.101.0/24",
    "10.0.105.0/24",
    "10.0.109.0/24"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_s3_endpoint = true
  create_igw = true
  tags = module.network_label.tags
}
