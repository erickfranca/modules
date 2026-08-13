variable "aws_region" {
  description = "Região AWS onde os repositórios ECR serão criados."
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "Usuário ou organização do GitHub dona dos repositórios de serviço."
  type        = string
  default     = "erickfranca@34513143"
}

variable "services" {
  description = "Lista de serviços do lab. Adicionar um serviço novo = adicionar um item aqui."
  type        = list(string)
  default = [
    "order-service",
    "payment-service",
    "shipping-service",
    "inventory-service",
  ]
}
