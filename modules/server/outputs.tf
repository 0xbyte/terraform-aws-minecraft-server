output "public_ip" {
  value = module.ec2.public_ip[0]
}
output "minecraft_port" {
  value = var.mc_port
}

output "private_key_pem" {
  value = tls_private_key.ec2_ssh.private_key_pem
}