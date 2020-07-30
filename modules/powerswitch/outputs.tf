output "server_status_url" {
  value = "http://${aws_route53_record.dns_record.name}/status"
}