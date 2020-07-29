output "start_server_url" {
  value = "http://${aws_route53_record.dns_record.name}/start"
}

output "stop_server_url" {
  value = "http://${aws_route53_record.dns_record.name}/stop"
}

output "get_server_status_url" {
  value = "http://${aws_route53_record.dns_record.name}/status"
}