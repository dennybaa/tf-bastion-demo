variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones where subnets will be created"
}

variable "subnets_per_az_count" {
  type        = number
  description = <<-EOT
    The number of subnet of each type (public or private) to provision per Availability Zone.
    EOT
  default     = 1

  validation {
    condition = var.subnets_per_az_count > 0
    # Validation error messages must be on a single line, among other restrictions.
    # See https://github.com/hashicorp/terraform/issues/24123
    error_message = "The `subnets_per_az` value must be greater than 0."
  }
}

variable "subnets_per_az_names" {
  type = list(string)

  description = <<-EOT
    The subnet names of each type (public or private) to provision per Availability Zone.
    This variable is optional.
    If a list of names is provided, the list items will be used as keys in the outputs `named_private_subnets_map`, `named_public_subnets_map`,
    `named_private_route_table_ids_map` and `named_public_route_table_ids_map`
    EOT
  default     = ["common"]
}

variable "bastion_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Bastion instance type"
}

variable "bastion_user_data" {
  type        = list(string)
  default     = []
  description = "User data content"
}

variable "ssh_key_path" {
  type        = string
  description = "Save location for ssh public keys generated by the module"
}

variable "instance_name" {
  type        = string
  description = "The name of private instance"
}

variable "instance_type" {
  type        = string
  description = "The type of the private instance"
}

variable "security_group_rules" {
  type        = list(any)
  description = <<-EOT
    A list of maps of Security Group rules for the private instance. 
    The values of map is fully complated with `aws_security_group_rule` resource. 
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}

variable "ami" {
  type        = string
  description = "The AMI to use for the target instance. By default uses Ubuntu 22.04"
  default     = ""
}

variable "ami_owner" {
  type        = string
  description = "Owner of the given AMI (ignored if `ami` unset, required if set)"
  default     = ""
}
