output "Access to Services" {
  description = "Public access to services of instance"
  value       = ["SSH: ssh -i keys/test_key centos@${aws_instance.test.public_ip} \nPrometheus: http://${aws_instance.test.public_ip}:9090 \nGrafana: http://${aws_instance.test.public_ip}:3000"]
}
