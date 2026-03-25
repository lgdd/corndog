output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.corndog.id
}

output "public_ip" {
  description = "Public IP of the corndog demo instance"
  value       = aws_instance.corndog.public_ip
}

output "app_url" {
  description = "URL to access the corndog web UI"
  value       = "http://${aws_instance.corndog.public_ip}:9080"
}

output "ssm_connect" {
  description = "Connect via SSM (no SSH key needed)"
  value       = "aws ssm start-session --target ${aws_instance.corndog.id}"
}
