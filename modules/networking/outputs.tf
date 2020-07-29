output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_id" {
  value = module.vpc.public_subnets[0]
}

output "s3_prefix_list_id" {
  value = module.vpc.vpc_endpoint_s3_pl_id
}