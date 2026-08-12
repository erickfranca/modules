# ---------------------------------------------------------------------------
# Repositório ECR — onde a imagem do serviço vai morar
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name = var.service_name

  # MUTABLE permite sobrescrever a tag :latest a cada build.
  # Em produção, IMMUTABLE é mais seguro (garante que uma tag nunca muda de
  # conteúdo), mas exige que você nunca reutilize tags — inclusive :latest.
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    # Escaneia a imagem em busca de CVEs assim que ela chega no registry.
    # É complementar ao Trivy: o Trivy roda antes do push (bloqueia), este
    # roda depois (detecta CVE nova em imagem já publicada).
    scan_on_push = true
  }

  # Permite que `terraform destroy` remova o repositório mesmo com imagens
  # dentro. Conveniente em lab; perigoso em produção — deixe false lá.
  force_delete = true

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Lifecycle policy — impede o registry de crescer para sempre
# ---------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter apenas as N imagens sem tag mais recentes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Trust policy — QUEM pode assumir esta role
#
# Esta é a parte crítica. A condição sub amarra a role a um único
# repositório GitHub e a um único branch. Sem ela, qualquer repositório
# do GitHub no mundo poderia assumir esta role.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # A audience precisa bater com o client_id_list do provedor OIDC.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # O subject identifica origem exata do token: repo + branch.
    # StringEquals (não StringLike) — sem wildcard, sem brecha.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "${var.service_name}-ci-role"
  description        = "Role assumida pelo GitHub Actions de ${var.github_repo} para publicar no ECR"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # Credenciais expiram em 1h. O job de CI dura minutos; não há motivo
  # para uma sessão mais longa.
  max_session_duration = 3600

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Permission policy — O QUE a role pode fazer depois de assumida
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ecr_push" {
  # GetAuthorizationToken é uma ação de conta, não de repositório.
  # A AWS não aceita escopo por recurso aqui — precisa ser "*".
  # Ela só devolve um token de login; não dá acesso a nenhuma imagem.
  statement {
    sid       = "ECRGetAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # As ações que mexem em imagem são escopadas a ESTE repositório.
  # É isso que impede o CI do order-service de publicar no payment-service.
  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "${var.service_name}-ecr-push"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
