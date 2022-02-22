output "cloudwatch_to_firehose_trust_arn" {
  description = "cloudwatch log subscription filter role_arn"
  value       = aws_iam_role.cloudwatch_to_firehose_trust.arn
}

output "destination_firehose_arn" {
  description = "cloudwatch log subscription filter - Firehose destination arn"
  value       = aws_kinesis_firehose_delivery_stream.kinesis_firehose.arn
}

locals {
  _singleton      = var.name_cloudwatch_logs_to_ship == "" ? [] : [var.name_cloudwatch_logs_to_ship]
  _group          = var.prefix_cloudwatch_logs_to_ship == "" ? [] : data.aws_cloudwatch_log_groups.log_groups[*].log_group_names
  combined_groups = concat(local._singleton, local._group)
}

output "log_group_names" {
  description = "the log group names being handled by this module"
  value       = local.combined_groups
}
