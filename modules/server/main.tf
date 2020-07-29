module "server_label" {
  source = "cloudposse/label/null"
  version = "0.16.0"
  namespace = "minecraft"
  name = "server"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Server"
  }
}

resource "random_string" "bucket_suffix" {
  length = 10
  special = false
  upper = false
}

module "bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "1.9.0"
  bucket = "${module.server_label.id}-${random_string.bucket_suffix.result}"
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
  tags = module.server_label.tags
}

locals {
  mc_server_files_path = "${path.root}/mc_server_files"
}

resource "aws_s3_bucket_object" "server_files" {
  for_each = fileset(local.mc_server_files_path, "**")
  bucket = module.bucket.this_s3_bucket_id
  key = each.value
  source = "${local.mc_server_files_path}/${each.value}"
}

module "ec2_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "2.12.0"
  role_name = module.server_label.id
  create_role = true
  create_instance_profile = true
  tags = module.server_label.tags
  role_requires_mfa = false
  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [module.ec2_iam_role_policy.arn]
}

module "ec2_iam_role_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "2.12.0"
  name        = module.server_label.id
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
  version = "3.13.0"
  name = "${module.server_label.id}-ec2"
  description = "Allow SSH on 22 and TCP on ${var.mc_port} from anywhere. Allow egress only to S3."
  vpc_id = var.vpc_id
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
  egress_rules = ["http-80-tcp", "https-443-tcp"]
  egress_prefix_list_ids = [var.s3_prefix_list_id]
  tags = module.server_label.tags
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
  template = file("${path.module}/bin/user_data.sh")

  vars = {
    mc_root = var.mc_root_directory
    mc_bucket = module.bucket.this_s3_bucket_id
    mc_backup_freq = var.mc_backup_freq
    java_mx_mem = var.java_mx_mem
    java_ms_mem = var.java_ms_mem
  }
}

resource "tls_private_key" "ec2_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_ssh" {
  key_name = module.server_label.id
  public_key = tls_private_key.ec2_ssh.public_key_openssh
  tags = module.server_label.tags

  // Wait for server files to be uploaded before creating key pair (which in turn blocks creation of instance)
  depends_on = [aws_s3_bucket_object.server_files]
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "2.15.0"
  name = module.server_label.id
  key_name = aws_key_pair.ec2_ssh.key_name
  ami = data.aws_ami.amazon-linux-2.image_id
  instance_type = "t2.medium"
  iam_instance_profile = module.ec2_iam_role.this_iam_instance_profile_name
  user_data = data.template_file.user_data.rendered
  subnet_id = var.subnet_id
  vpc_security_group_ids = [module.ec2_security_group.this_security_group_id]
  associate_public_ip_address = true
  tags = module.server_label.tags
}
