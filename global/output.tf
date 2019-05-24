output "Access to Services" {
  description = "Public access to services of instance"
  value       = ["Please wait 1 minute before accessing the services \n SSH: ssh -i keys/test_key centos@${aws_instance.test.public_ip} \n Prometheus: http://${aws_instance.test.public_ip}:9090 \n Grafana: http://${aws_instance.test.public_ip}:3000"]
}
