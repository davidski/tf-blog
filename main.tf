provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 1.54"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

provider "aws.east_1" {
  region  = "us-east-1"
  profile = "${var.aws_profile}"
  version = "~> 1.54"

  assume_role {
    role_arn = "arn:aws:iam::754135023419:role/administrator-service"
  }
}

# Data source for the availability zones in this zone
data "aws_availability_zones" "available" {}

# Data source for current account number
data "aws_caller_identity" "current" {}

# Data source for ACM certificate
data "aws_acm_certificate" "blog" {
  provider = "aws.east_1"
  domain   = "blog.severski.net"
}

# Data source for main infrastructure state
data "terraform_remote_state" "main" {
  backend = "s3"

  config {
    bucket  = "infrastructure-severski"
    key     = "terraform/infrastructure.tfstate"
    region  = "us-west-2"
    encrypt = "true"
  }
}

# Find our target zone by id
data "aws_route53_zone" "zone" {
  zone_id = "${data.terraform_remote_state.main.severski_zoneid}"
}

/*
  -------------
  | CDN Setup |
  -------------
*/

# configure cloudfront SSL caching for S3 hosted static blog
module "blogcdn" {
  source = "git://github.com/davidski/tf-cloudfronts3.git"

  #source = "../../modules/tf-cloudfronts3"

  bucket_name         = "sisyphus-blog"
  origin_id           = "blog_bucket"
  alias               = "blog.severski.net"
  acm_certificate_arn = "${data.aws_acm_certificate.blog.arn}"
  project             = "${var.project}"
  audit_bucket        = "${data.terraform_remote_state.main.auditlogs}"
  comment             = "sysiphus-blog"
}
