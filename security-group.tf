module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.0.1"

  rules_map = local.target_rules_map
  vpc_id    = module.vpc.vpc_id

  enabled = true
  name    = var.instance_name
  context = module.this.context
}
