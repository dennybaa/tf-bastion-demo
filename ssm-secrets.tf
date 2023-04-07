module "secrets-manager" {
  source  = "lgallard/secrets-manager/aws"
  version = "0.7.0"

  secrets = {
    bastion-ssh-key = {
      description             = "Bastion ssh private key"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
  }

  tags = module.this.tags
}
