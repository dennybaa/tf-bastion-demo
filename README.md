# Terraform bastion demo

The sole task of this demo is to show the bastion and target host setup in AWS using terraform.

## Prerequisites

  * Bastion Host - The Bastion Host is an AWS EC2 instance which is publicly accessible over ssh on port 22.
  * Target Host - The Target Host is an AWS EC2 instance that is on a private subnet. The Target Host should be accessible via ssh from the Bastion Host.
  * Store any keys used in AWS Secrets Manage.

## TL;DR

Being a pure demo this setup doesn't strive to provide a complete quality solution. For simplicity only terraform is used. It's worth mentioning that a production ready solution:

  * Might use terragrunt or other tools to support multienv.
  * Might not use terraform at all :)
  * Might not use SSH bastion/jump host approach at all. For instance there's a small article ([How to securely connect EC2 via SSH with AWS Systems Manager](https://korniichuk.medium.com/session-manager-e724eb105eb7)) which suggests that there're better ways, but it contains links to better detailed sources.

This demo doesn't contain any work-from-zero development, it basically wrapps up usage (copy-pastes) of good-quality terraform modules, mostly from [Cloud Posse](https://github.com/cloudposse). Again there are many good-quality modules out there (like those from Anton Babenko), this is just matter of taste and match for a specific task.

### Demo

This demo doesn't deviate much from available examples, though it's worth mentioning that in this demo:

  * The target host is shipped with the recent Ubuntu LTS flavor.
  * ec2-instance-module has its built-in security group disabled, since the demo creates another one instead. This security group independently from the VPC default security group manages access from the bastion host to the target host.
  * This demo writes the private ssh key into AWS Secrets Manager without any IAM permissions configuration, just as is, to purely show that the secret data might or should be stored in cloud provider's secret management solution.

## Usage

It's supposed that the reader has AWS account, has already set the environment up and installed terraform. This demo doesn't explain or suggests how to do it, since this a considarable topic itself which might vary depending on the use-case. If the mentioned setup has been performed, you are ready to apply the configuration:

```
terraform init
terraform apply

terraform output
```

After applying configuration the output provides all the necessary details, specifically on how to connect to either the bastion or to the target host:

```
public_dns = "ec2-108-136-96-151.ap-southeast-3.compute.amazonaws.com"
ssh_bastion_command = "ssh -i ./secrets/eg-demo-bastion-ssh-key ec2-user@ec2-108-136-96-151.ap-southeast-3.compute.amazonaws.com"
ssh_target_command = <<EOT
# Add the private key into agent (done once)
ssh-add ./secrets/eg-demo-bastion-ssh-key

# Direct hop through bastion into the target host
ssh -At ec2-user@ec2-108-136-96-151.ap-southeast-3.compute.amazonaws.com "ssh ubuntu@172.16.20.121"

EOT
```

### Connecting to hosts

It's suggested to add the private key into ssh-agent for ease of usage (for more details on ssh-agent, please refer to `man ssh-agent`). Bellow I shortly describe what commands in the output do and how to connect to the target host:

1. We add the private key into the agent `ssh-add ./secrets/eg-demo-bastion-ssh-key`
2. We connect to the bastion and execute ssh command on it to jump into the target (mind `-At` flags) `ssh -At ec2-user@ec2-108-136-96-151.ap-southeast-3.compute.amazonaws.com "ssh ubuntu@172.16.20.121"`. Let's shortly cover these flags. `-A` enables agent forwarding, i.e. makes ssh-keys available for the bastion ssh session. While `-t` is required for pseudo-terminal allocation, since the inner ssh command is interactive.

### Clean up

Clean up all of the resources from AWS.

```
terraform destroy
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.62.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_key_pair"></a> [aws\_key\_pair](#module\_aws\_key\_pair) | cloudposse/key-pair/aws | 0.18.3 |
| <a name="module_ec2_bastion"></a> [ec2\_bastion](#module\_ec2\_bastion) | cloudposse/ec2-bastion-server/aws | 0.30.1 |
| <a name="module_ec2_instance"></a> [ec2\_instance](#module\_ec2\_instance) | cloudposse/ec2-instance/aws | 0.47.1 |
| <a name="module_instance_profile_label"></a> [instance\_profile\_label](#module\_instance\_profile\_label) | cloudposse/label/null | 0.25.0 |
| <a name="module_secrets-manager"></a> [secrets-manager](#module\_secrets-manager) | lgallard/secrets-manager/aws | 0.7.0 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | cloudposse/security-group/aws | 2.0.1 |
| <a name="module_subnets"></a> [subnets](#module\_subnets) | cloudposse/dynamic-subnets/aws | 2.1.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | cloudposse/vpc/aws | 2.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br>This is for some rare cases where resources want additional configuration of tags<br>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_ami"></a> [ami](#input\_ami) | The AMI to use for the target instance. By default uses Ubuntu 20.04 | `string` | `""` | no |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of the given AMI (ignored if `ami` unset, required if set) | `string` | `""` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br>in the order they appear in the list. New attributes are appended to the<br>end of the list. The elements of the list are joined by the `delimiter`<br>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Availability Zones where subnets will be created | `list(string)` | n/a | yes |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | Bastion instance type | `string` | `"t3.micro"` | no |
| <a name="input_bastion_user_data"></a> [bastion\_user\_data](#input\_bastion\_user\_data) | User data content | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "descriptor_formats": {},<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "labels_as_tags": [<br>    "unset"<br>  ],<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {},<br>  "tenant": null<br>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br>Map of maps. Keys are names of descriptors. Values are maps of the form<br>`{<br>   format = string<br>   labels = list(string)<br>}`<br>(Type is `any` so the map values can later be enhanced to provide additional options.)<br>`format` is a Terraform format string to be passed to the `format()` function.<br>`labels` is a list of labels, in order, to pass to `format()` function.<br>Label values will be normalized before being passed to `format()` so they will be<br>identical to how they appear in `id`.<br>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for keep the existing setting, which defaults to `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | The name of private instance | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The type of the private instance | `string` | n/a | yes |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br>Does not affect keys of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br>set as tag values, and output by this module individually.<br>Does not affect values of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br>Default is to include all labels.<br>Tags with empty values will not be included in the `tags` output.<br>Set to `[]` to suppress all generated tags.<br>**Notes:**<br>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br>This is the only ID element not also included as a `tag`.<br>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br>Characters matching the regex will be removed from the ID elements.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | A list of maps of Security Group rules for the private instance. <br>The values of map is fully complated with `aws_security_group_rule` resource. <br>To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule . | `list(any)` | n/a | yes |
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | Save location for ssh public keys generated by the module | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_subnets_per_az_count"></a> [subnets\_per\_az\_count](#input\_subnets\_per\_az\_count) | The number of subnet of each type (public or private) to provision per Availability Zone. | `number` | `1` | no |
| <a name="input_subnets_per_az_names"></a> [subnets\_per\_az\_names](#input\_subnets\_per\_az\_names) | The subnet names of each type (public or private) to provision per Availability Zone.<br>This variable is optional.<br>If a list of names is provided, the list items will be used as keys in the outputs `named_private_subnets_map`, `named_public_subnets_map`,<br>`named_private_route_table_ids_map` and `named_public_route_table_ids_map` | `list(string)` | <pre>[<br>  "common"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_dns"></a> [public\_dns](#output\_public\_dns) | Public DNS of instance (or DNS of EIP) |
| <a name="output_ssh_bastion_command"></a> [ssh\_bastion\_command](#output\_ssh\_bastion\_command) | ssh command to connect to the bastion host |
| <a name="output_ssh_target_command"></a> [ssh\_target\_command](#output\_ssh\_target\_command) | ssh command to connect to the target host |
