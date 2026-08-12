output "ecr_repository_urls" {
  description = "URL do ECR de cada serviço, por nome."
  value       = { for k, m in module.service_ci : k => m.ecr_repository_url }
}

output "ci_role_arns" {
  description = "ARN da role de CI de cada serviço. Cole no workflow do repositório correspondente."
  value       = { for k, m in module.service_ci : k => m.ci_role_arn }
}
