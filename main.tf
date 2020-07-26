data "aws_caller_identity" "aws" {}

module "minecraft_server_label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace = "minecraft"
  name = "server"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Server"
  }
}

module "minecraft_network_label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace = "minecraft"
  name = "network"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Networking"
  }
}

module "minecraft_powerswitch_label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace = "minecraft"
  name = "powerswitch"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Power Switch"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = module.minecraft_network_label.id
  cidr = "10.0.0.0/16"
  azs = [
    var.availability_zone]
  private_subnets = []
  public_subnets = [
    "10.0.101.0/24"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_s3_endpoint = true
  create_igw = true
  tags = module.minecraft_network_label.tags
}

resource "random_string" "bucket_suffix" {
  length = 10
  special = false
  upper = false
}

module "bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "${module.minecraft_server_label.id}-${random_string.bucket_suffix.result}"
  create_bucket = true
  region = var.region
  acl = "private"
  force_destroy = false
  versioning = {
    enabled = true
  }
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  tags = module.minecraft_server_label.tags
}

module "ec2_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"
  role_name = module.minecraft_server_label.id
  create_role = true
  create_instance_profile = true
  tags = module.minecraft_server_label.tags
  role_requires_mfa = false
  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [module.ec2_iam_role_policy.arn]
}

module "ec2_iam_role_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 2.0"
  name        = module.minecraft_server_label.id
  path        = "/"
  description = "Policy that allows the Minecraft server to pull and push files to the S3 asset bucket"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "${module.bucket.this_s3_bucket_arn}/*"
    },
    {
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${module.bucket.this_s3_bucket_arn}"
    }
  ]
}
EOF
}

module "ec2_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  name = "minecraft-server-ec2-sg"
  description = "Allow SSH on 22 and TCP on ${var.mc_port} from anywhere. Allow all egress."
  vpc_id = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port = var.mc_port
      to_port = var.mc_port
      protocol = "tcp"
      description = "Minecraft server"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules = [
    "all-all"]
  tags = module.minecraft_server_label.tags
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    mc_root = var.mc_root_directory
    mc_bucket = module.bucket.this_s3_bucket_id
    mc_backup_freq = var.mc_backup_freq
    mc_version = var.mc_version
    mc_type = var.mc_type
    java_mx_mem = var.java_mx_mem
    java_ms_mem = var.java_ms_mem
  }
}

resource "tls_private_key" "ec2_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_ssh" {
  key_name = module.minecraft_server_label.id
  public_key = tls_private_key.ec2_ssh.public_key_openssh
  tags = module.minecraft_server_label.tags
}

module "server" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name = module.minecraft_server_label.id
  key_name = aws_key_pair.ec2_ssh.key_name
  ami = data.aws_ami.amazon-linux-2.image_id
  instance_type = "t2.medium"
  iam_instance_profile = module.ec2_iam_role.this_iam_instance_profile_name
  user_data = data.template_file.user_data.rendered
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.ec2_security_group.this_security_group_id]
  associate_public_ip_address = true
  tags = module.minecraft_server_label.tags
}
