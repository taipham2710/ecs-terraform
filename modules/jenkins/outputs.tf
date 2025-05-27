# modules/jenkins/outputs.tf
output "instance_id" {
  description = "ID of the Jenkins instance"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP of the Jenkins instance"
  value       = aws_instance.jenkins.public_ip
}

output "private_ip" {
  description = "Private IP of the Jenkins instance"
  value       = aws_instance.jenkins.private_ip
}