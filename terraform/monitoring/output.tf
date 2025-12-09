output "sns_topic_arn" {
  description = "SNS topic used for alarm notifications (created or provided)."
  value       = local.sns_topic_arn
}

output "flow_log_group_name" {
  description = "CloudWatch log group capturing VPC flow logs."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "flow_log_id" {
  description = "Identifier of the VPC flow log delivering to CloudWatch."
  value       = aws_flow_log.vpc.id
}

output "cpu_alarm_arns" {
  description = "CPU utilization alarm ARNs per instance."
  value       = [for alarm in aws_cloudwatch_metric_alarm.cpu_high : alarm.arn]
}

output "status_check_alarm_arns" {
  description = "Instance status check alarm ARNs per instance."
  value       = [for alarm in aws_cloudwatch_metric_alarm.status_check_failed : alarm.arn]
}

output "network_in_alarm_arns" {
  description = "Network inbound alarm ARNs per instance."
  value       = [for alarm in aws_cloudwatch_metric_alarm.network_in : alarm.arn]
}

output "port_alarm_arns" {
  description = "Alarm ARNs for SSH/HTTP/HTTPS access observed via flow logs."
  value = [
    aws_cloudwatch_metric_alarm.ssh_access.arn,
    aws_cloudwatch_metric_alarm.http_access.arn,
    aws_cloudwatch_metric_alarm.https_access.arn,
  ]
}

