locals {
  output_ssh_endpoint = "${module.ec2_bastion.ssh_user}@${module.ec2_bastion.public_dns}"
  output_ssh_keypath  = pathexpand(module.aws_key_pair.private_key_filename)
}

output "public_dns" {
  description = "Public DNS of instance (or DNS of EIP)"
  value       = module.ec2_bastion.public_dns
}

output "ssh_bastion_command" {
  description = "ssh command to connect to the bastion host"
  value       = "ssh -i ${local.output_ssh_keypath} ${local.output_ssh_endpoint}"
}

output "ssh_target_command" {
  description = "ssh command to connect to the target host"
  value       = <<-EOF
    # Add the private key into agent (done once)
    ssh-add ${local.output_ssh_keypath}

    # Direct hop through bastion into the target host
    ssh -At ${local.output_ssh_endpoint} "ssh ubuntu@${module.ec2_instance.private_ip}"
    EOF
}
