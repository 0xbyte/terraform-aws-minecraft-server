resource "local_file" "private_key" {
  content              = module.server.private_key_pem
  filename             = "${path.module}/ec2-private-key.pem"
  directory_permission = "0700"
  file_permission      = "0700"
}

output "ssh_command" {
  value = "ssh -i ${path.module}/ec2-private-key.pem ec2-user@${module.server.public_ip}"
}

output "minecraft_server" {
  value = "${module.server.public_ip}:${module.server.minecraft_port}"
}

output "mc_server_files_uploaded_to_bucket" {
  value = module.server.mc_server_files_uploaded_to_bucket
}

output "server_files_bucket_name" {
  value = module.server.bucket_name
}

output "start_server_url" {
  value = module.powerswitch.start_server_url
}

output "stop_server_url" {
  value = module.powerswitch.stop_server_url
}

output "get_server_status_url" {
  value = module.powerswitch.get_server_status_url
}
