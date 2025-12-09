variable "vpc_id" {
  description = "VPC ID to enable flow logs for and observe port-level traffic."
  type        = string
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to monitor with native CloudWatch metrics."
  type        = list(string)
}

variable "alarm_name_prefix" {
  description = "Prefix applied to CloudWatch alarms, SNS topic, and log group names."
  type        = string
  default     = "ec2-monitoring"
}

variable "create_sns_topic" {
  description = "Whether to create a dedicated SNS topic for alarm notifications."
  type        = bool
  default     = true
}

variable "existing_sns_topic_arn" {
  description = "Use an existing SNS topic ARN instead of creating a new one."
  type        = string
  default     = ""
}

variable "alarm_email_addresses" {
  description = "Email recipients for alarm notifications (only used when creating the SNS topic)."
  type        = list(string)
  default     = []
}

variable "flow_log_retention_days" {
  description = "Retention (days) for the VPC flow log CloudWatch log group."
  type        = number
  default     = 14
}

variable "port_connection_threshold" {
  description = "Minimum number of accepted connections per evaluation window that triggers the port alarms."
  type        = number
  default     = 1
}

variable "port_period_seconds" {
  description = "Period (seconds) for evaluating port connection alarms sourced from flow logs."
  type        = number
  default     = 300
}

variable "port_evaluation_periods" {
  description = "Number of periods for evaluating port alarms."
  type        = number
  default     = 1
}

variable "cpu_high_threshold" {
  description = "CPU utilization percentage that raises an alarm."
  type        = number
  default     = 80
}

variable "network_in_threshold_bytes" {
  description = "Inbound network bytes per period that raises an alarm."
  type        = number
  default     = 104857600 # 100 MB
}

variable "instance_metric_period_seconds" {
  description = "Period (seconds) for EC2 metric alarms (CPU, status checks, network)."
  type        = number
  default     = 300
}

variable "instance_metric_evaluation_periods" {
  description = "Number of periods for evaluating EC2 metric alarms."
  type        = number
  default     = 2
}

