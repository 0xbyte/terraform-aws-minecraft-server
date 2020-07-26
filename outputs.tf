output "public_key_openssh" {
  value = tls_private_key.ec2_ssh.*.public_key_openssh
}

output "public_key" {
  value = tls_private_key.ec2_ssh.*.public_key_pem
}

output "private_key" {
  value = tls_private_key.ec2_ssh.*.private_key_pem
}

resource "local_file" "private_key" {
  content              = tls_private_key.ec2_ssh.private_key_pem
  filename             = "${path.module}/ec2-private-key.pem"
  directory_permission = "0700"
  file_permission      = "0700"
}

output "ssh_command" {
  value = "ssh -i ${path.module}/ec2-private-key.pem ec2-user@${module.server.public_ip[0]}"
}

output "minecraft_server" {
  value = "${module.server.public_ip[0]}:${var.mc_port}"
}