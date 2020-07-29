variable "vpc_id" {
  description = "The id of the VPC to deploy the Lambda and load balancer into"
  type = string
}

variable "subnet_ids" {
  description = "The ids of the subnets to deploy infrastructure into"
  type = list(string)
}

variable "region" {
  description = "AWS region to deploy infrastructure into"
  type = string
}

variable "server_instance_id" {
  description = "Instance id of the Minecraft server"
  type = string
}

variable "server_instance_arn" {
  description = "ARN of the Minecraft server"
  type = string
}

variable "hostname" {
  description = "Hostname of the DNS record that will be created to point to the load balancer"
  type = string
}

variable "hosted_zone_name" {
  description = "Hosted zone name of the DNS record that will be created to point to the load balancer"
  type = string
}