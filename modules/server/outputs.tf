output "public_ip" {
  value = module.ec2.public_ip[0]
}

output "minecraft_port" {
  value = var.mc_port
}

output "private_key_pem" {
  value = tls_private_key.ec2_ssh.private_key_pem
}

output "mc_server_files_uploaded_to_bucket" {
  value = length(fileset("${path.root}/mc_server_files", "**"))
}

output "instance_id" {
  value = module.ec2.id[0]
}

output "instance_arn" {
  value = module.ec2.arn[0]
}

output "bucket_name" {
  value = module.bucket.this_s3_bucket_id
}