output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.public_subnets
}

output "s3_prefix_list_id" {
  value = module.vpc.vpc_endpoint_s3_pl_id
}