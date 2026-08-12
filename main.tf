# O provedor OIDC já foi criado manualmente via CLI e é único por conta.
# Usamos um data source para referenciá-lo sem que o Terraform assuma
# a posse dele — assim um `terraform destroy` não remove um recurso
# compartilhado por outros labs.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# for_each cria uma instância do módulo por serviço da lista.
# Diferente de count, o for_each indexa por chave (o nome do serviço),
# então remover um item do meio da lista não recria os outros.
module "service_ci" {
  source   = "./modules/service-ci"
  for_each = toset(var.services)

  service_name      = each.value
  github_repo       = "${var.github_owner}/${each.value}"
  github_branch     = "main"
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  tags = {
    Service = each.value
  }
}
