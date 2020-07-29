variable "power_switch_hostname" {
  description = "Hostname of the DNS record that will be created to point to the power switch's load balancer"
  type = string
}

variable "power_switch_hosted_zone_name" {
  description = "Hosted zone name of the DNS record that will be created to point to the power switch's load balancer"
  type = string
}

variable "region" {
  description = "AWS region to deploy infrastructure into"
  type = string
  default = "eu-west-2"
}

variable "availability_zones" {
  description = "Availability zones inside the region to deploy infrastructure into"
  type = list(string)
  default = [
    "eu-west-2a",
    "eu-west-2b",
    "eu-west-2c"]
}

variable "mc_port" {
  description = "TCP port for minecraft"
  type = number
  default = 25565
}

variable "mc_root_directory" {
  description = "Where to install minecraft on your instance"
  type = string
  default = "/home/minecraft"
}

variable "mc_backup_freq" {
  description = "How often (mins) to sync to S3"
  type = number
  default = 5
}

variable "java_ms_mem" {
  description = "Java initial and minimum heap size"
  type = string
  default = "2G"
}

variable "java_mx_mem" {
  description = "Java maximum heap size"
  type = string
  default = "2G"
}
