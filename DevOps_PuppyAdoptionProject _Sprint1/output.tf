output "jenkins_server" {
value = aws_instance.jenkins_server.public_ip
  
}

output "app-server" {
  value = aws_instance.app_server.public_ip
}