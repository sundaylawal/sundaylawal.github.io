output "tomcat_server" {
value = aws_instance.tomcat_server.public_ip
  
}

output "jenkins_server" {
value = aws_instance.jenkins_server.public_ip
  
}

output "set6_A_record" {
  value = aws_route53_record.set6_A_record.alias
}