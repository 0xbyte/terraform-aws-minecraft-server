variable "region" {
  description = "AWS region to deploy the server into"
  type = string
}

variable "availability_zone" {
  description = "Availability zone inside the region to deploy the server into"
  type = string
}

variable "vpc_id" {
  description = "The id of the VPC to deploy the server into"
  type = string
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the server into"
  type = string
}

variable "s3_prefix_list_id" {
  description = "The id of the S3 VPC endpoint's prefix list"
  type = string
}

variable "mc_port" {
  description = "TCP port for minecraft"
  type = number
}

variable "mc_root_directory" {
  description = "Where to install minecraft on your instance"
  type = string
}

variable "mc_backup_freq" {
  description = "How often (mins) to sync to S3"
  type = number
}

variable "java_ms_mem" {
  description = "Java initial and minimum heap size"
  type = string
}

variable "java_mx_mem" {
  description = "Java maximum heap size"
  type = string
}
