variable "region" {
  description = "AWS region to deploy infrastructure into"
  type = string
  default = "eu-west-2"
}

variable "availability_zone" {
  description = "Availability zone inside the region to deploy infrastructure into"
  type = string
  default = "eu-west-2a"
}

variable "mc_port" {
  description = "TCP port for minecraft"
  type        = number
  default     = 25565
}

variable "mc_root_directory" {
  description = "Where to install minecraft on your instance"
  type        = string
  default     = "/home/minecraft"
}

variable "mc_backup_freq" {
  description = "How often (mins) to sync to S3"
  type        = number
  default     = 5
}

variable "java_ms_mem" {
  description = "Java initial and minimum heap size"
  type        = string
  default     = "2G"
}

variable "java_mx_mem" {
  description = "Java maximum heap size"
  type        = string
  default     = "2G"
}
