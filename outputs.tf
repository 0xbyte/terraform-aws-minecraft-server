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