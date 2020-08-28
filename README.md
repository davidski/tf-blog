# Personal Blog

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0, < 0.14.0 |
| aws | ~> 2.70 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.70 |
| aws.east\_1 | ~> 2.70 |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_profile | Name of AWS profile to use for API access. | `string` | `"default"` | no |
| aws\_region | n/a | `string` | `"us-west-2"` | no |
| project | Default value for project tag. | `string` | `"personal-blog"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_arn | n/a |
| domain\_name | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->