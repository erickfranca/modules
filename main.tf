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

# ---------------------------------------------------------------------------
# IAM Role para o CI/CD do repositório 'erickfranca/modules' (Este repositório)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_infra_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Autoriza execuções da branch main E de Pull Requests deste repositório
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${var.github_owner}/modules:ref:refs/heads/main",
        "repo:${var.github_owner}/modules:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_infra" {
  name               = "modules-infra-ci-role"
  description        = "Role assumida pelo GitHub Actions para gerenciar a infraestrutura via Terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_infra_assume_role.json

  tags = {
    ManagedBy = "terraform"
  }
}

# Concede permissões administrativas/necessárias para a Role gerenciar os recursos
resource "aws_iam_role_policy_attachment" "infra_admin" {
  role       = aws_iam_role.github_actions_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
