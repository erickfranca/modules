terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # ~> 6.58 permite 6.58.x e minors acima dentro do 6.x.
      # O provider AWS 6.x trouxe breaking changes em relação ao 5.x,
      # por isso a major fica presa.
      version = "~> 6.58"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "node-obs-lab"
      ManagedBy = "terraform"
    }
  }
}
