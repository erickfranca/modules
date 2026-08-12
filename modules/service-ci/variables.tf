variable "service_name" {
  description = "Nome do serviço. Vira o nome do repositório ECR e prefixo da role IAM."
  type        = string
}

variable "github_repo" {
  description = "Repositório GitHub no formato owner/repo. Usado na condição sub da trust policy."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "github_repo deve estar no formato owner/repo (ex: erickfranca/order-service)."
  }
}

variable "github_branch" {
  description = "Branch autorizado a assumir a role. Apenas este branch consegue publicar no ECR."
  type        = string
  default     = "main"
}

variable "oidc_provider_arn" {
  description = "ARN do provedor OIDC do GitHub Actions nesta conta AWS."
  type        = string
}

variable "image_retention_count" {
  description = "Quantidade de imagens sem tag a manter antes da limpeza automática."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos criados pelo módulo."
  type        = map(string)
  default     = {}
}
