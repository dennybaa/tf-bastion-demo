locals {
  ami = var.ami != "" ? var.ami : join("", data.aws_ami.ubuntu.*.image_id)

  target_rules_map = {
    user_defined = var.security_group_rules,

    ## Allow only bastion host security memebers to access targert instance SSH port
    bastion = [
      {
        type                     = "ingress"
        protocol                 = "tcp"
        from_port                = 22
        to_port                  = 22
        description              = "Allows SSH access from the bastion host"
        source_security_group_id = module.ec2_bastion.security_group_id
      }
    ]
  }
}

provider "aws" {
  region = var.region
}

module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.3"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_key_path
  generate_ssh_key    = true

  context = module.this.context
}

module "ec2_bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.30.1"

  enabled = module.this.enabled

  instance_type                 = var.bastion_instance_type
  security_groups               = []
  subnets                       = module.subnets.public_subnet_ids
  key_name                      = module.aws_key_pair.key_name
  user_data                     = var.bastion_user_data
  vpc_id                        = module.vpc.vpc_id
  associate_public_ip_address   = true
  root_block_device_encrypted   = true
  metadata_http_tokens_required = true

  context = module.this.context
}

module "instance_profile_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = distinct(compact(concat(module.this.attributes, ["profile"])))

  context = module.this.context
  name    = var.instance_name
}

data "aws_iam_policy_document" "test" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test" {
  name               = module.instance_profile_label.id
  assume_role_policy = data.aws_iam_policy_document.test.json
  tags               = module.instance_profile_label.tags
}

# https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/terraform-0.13-examples/module-depends-on
resource "aws_iam_instance_profile" "test" {
  name = module.instance_profile_label.id
  role = aws_iam_role.test.name
}

module "ec2_instance" {
  source  = "cloudposse/ec2-instance/aws"
  version = "0.47.1"
  enabled = true

  ## disable creation of the security group provided by default (a custom one is used)
  security_group_enabled      = false
  name                        = var.instance_name
  ami                         = local.ami
  ami_owner                   = var.ami_owner
  vpc_id                      = module.vpc.vpc_id
  subnet                      = module.subnets.private_subnet_ids[0]
  security_groups             = [module.vpc.vpc_default_security_group_id, module.security_group.id]
  assign_eip_address          = false
  associate_public_ip_address = false
  instance_type               = var.instance_type
  instance_profile            = aws_iam_instance_profile.test.name
  ssh_key_pair                = module.aws_key_pair.key_name

  context = module.this.context
}

## Use the recent Ubuntu LTS release
data "aws_ami" "ubuntu" {
  count       = var.ami == "" ? 1 : 0
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
