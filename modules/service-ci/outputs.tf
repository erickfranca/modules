output "ecr_repository_url" {
  description = "URL do repositório ECR. Usada como destino do docker push."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN do repositório ECR."
  value       = aws_ecr_repository.this.arn
}

output "ci_role_arn" {
  description = "ARN da role assumida pelo GitHub Actions. Vai no workflow."
  value       = aws_iam_role.ci.arn
}
