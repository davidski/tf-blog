provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  version = "~> 2.7"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

provider "aws" {
  alias   = "east_1"
  region  = "us-east-1"
  profile = var.aws_profile
  version = "~> 2.7"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

# Data source for the availability zones in this zone
data "aws_availability_zones" "available" {}

# Data source for current account number
data "aws_caller_identity" "current" {}

# Data source for main infrastructure state
data "terraform_remote_state" "main" {
  backend = "s3"

  config = {
    bucket  = "infrastructure-severski"
    key     = "terraform/infrastructure.tfstate"
    region  = "us-west-2"
    encrypt = "true"
  }
}

# Find our target zone by id
data "aws_route53_zone" "zone" {
  zone_id = data.terraform_remote_state.main.outputs.severski_main_zoneid
}

/*
  -------------
  | CDN Setup |
  -------------
*/

resource "aws_acm_certificate" "blog" {
  provider                = aws.east_1

  domain_name               = "blog.severski.net"
  validation_method         = "DNS"

  tags = {
    managed_by = "Terraform"
    project    = var.project
    Name       = "Sisyphus blog"
  }

}

resource "aws_route53_record" "cert_validation_assets" {
  name     = aws_acm_certificate.blog.domain_validation_options.0.resource_record_name
  type     = aws_acm_certificate.blog.domain_validation_options.0.resource_record_type
  zone_id  = data.aws_route53_zone.zone.zone_id
  records  = [aws_acm_certificate.blog.domain_validation_options.0.resource_record_value]
  ttl      = 1800
  provider = aws.east_1
}

resource "aws_acm_certificate_validation" "blog" {
  certificate_arn         = aws_acm_certificate.blog.arn
  validation_record_fqdns = [aws_route53_record.cert_validation_assets.fqdn]
  provider                = aws.east_1
}

# configure cloudfront SSL caching for S3 hosted static blog
module "blogcdn" {
  providers                = { aws = aws.east_1, aws.bucket = aws}
  source = "git://github.com/davidski/tf-cloudfronts3.git"

  #source = "../../modules/tf-cloudfronts3"

  bucket_name         = "sisyphus-blog"
  origin_id           = "blog_bucket"
  alias               = ["blog.severski.net"]
  acm_certificate_arn = aws_acm_certificate.blog.arn
  project             = var.project
  audit_bucket        = data.terraform_remote_state.main.outputs.auditlogs
  comment             = "sysiphus-blog"
}
