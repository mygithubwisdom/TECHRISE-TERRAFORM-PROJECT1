terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  custom_namespace = "${var.alarm_name_prefix}/flow-logs"
  sns_topic_arn    = var.existing_sns_topic_arn != "" ? var.existing_sns_topic_arn : (var.create_sns_topic ? aws_sns_topic.monitoring[0].arn : null)
  alarm_actions    = local.sns_topic_arn == null ? [] : [local.sns_topic_arn]
}

# Optional notification channel for alarms
resource "aws_sns_topic" "monitoring" {
  count = var.create_sns_topic && var.existing_sns_topic_arn == "" ? 1 : 0

  name = "${var.alarm_name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.create_sns_topic && var.existing_sns_topic_arn == "" ? toset(var.alarm_email_addresses) : []

  topic_arn = aws_sns_topic.monitoring[0].arn
  protocol  = "email"
  endpoint  = each.key
}

# VPC flow logs -> CloudWatch for port-specific visibility (22/80/443)
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.alarm_name_prefix}"
  retention_in_days = var.flow_log_retention_days
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.alarm_name_prefix}-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.alarm_name_prefix}-flowlogs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  vpc_id               = var.vpc_id
  traffic_type         = "ALL"
}

# Metric filters for specific ports
resource "aws_cloudwatch_log_metric_filter" "ssh" {
  name           = "${var.alarm_name_prefix}-ssh-accepted"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, interfaceid, srcaddr, dstaddr, srcport, dstport=22, protocol=6, packets, bytes, start, end, action=ACCEPT, logstatus]"

  metric_transformation {
    name      = "${var.alarm_name_prefix}-ssh-accepted"
    namespace = local.custom_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http" {
  name           = "${var.alarm_name_prefix}-http-accepted"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, interfaceid, srcaddr, dstaddr, srcport, dstport=80, protocol=6, packets, bytes, start, end, action=ACCEPT, logstatus]"

  metric_transformation {
    name      = "${var.alarm_name_prefix}-http-accepted"
    namespace = local.custom_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "https" {
  name           = "${var.alarm_name_prefix}-https-accepted"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, interfaceid, srcaddr, dstaddr, srcport, dstport=443, protocol=6, packets, bytes, start, end, action=ACCEPT, logstatus]"

  metric_transformation {
    name      = "${var.alarm_name_prefix}-https-accepted"
    namespace = local.custom_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ssh_access" {
  alarm_name          = "${var.alarm_name_prefix}-ssh-access"
  namespace           = local.custom_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.ssh.metric_transformation[0].name
  statistic           = "Sum"
  period              = var.port_period_seconds
  evaluation_periods  = var.port_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.port_connection_threshold
  alarm_description   = "Triggers when SSH (22) connections are observed in VPC flow logs."
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "http_access" {
  alarm_name          = "${var.alarm_name_prefix}-http-access"
  namespace           = local.custom_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.http.metric_transformation[0].name
  statistic           = "Sum"
  period              = var.port_period_seconds
  evaluation_periods  = var.port_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.port_connection_threshold
  alarm_description   = "Triggers when HTTP (80) connections are observed in VPC flow logs."
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "https_access" {
  alarm_name          = "${var.alarm_name_prefix}-https-access"
  namespace           = local.custom_namespace
  metric_name         = aws_cloudwatch_log_metric_filter.https.metric_transformation[0].name
  statistic           = "Sum"
  period              = var.port_period_seconds
  evaluation_periods  = var.port_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.port_connection_threshold
  alarm_description   = "Triggers when HTTPS (443) connections are observed in VPC flow logs."
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

# EC2 native metrics
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  for_each = toset(var.instance_ids)

  alarm_name          = "${var.alarm_name_prefix}-${each.key}-cpu-high"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = var.instance_metric_period_seconds
  evaluation_periods  = var.instance_metric_evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_high_threshold
  alarm_description   = "CPU utilization above threshold for instance ${each.key}."
  dimensions = {
    InstanceId = each.key
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  for_each = toset(var.instance_ids)

  alarm_name          = "${var.alarm_name_prefix}-${each.key}-status-check"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = var.instance_metric_period_seconds
  evaluation_periods  = var.instance_metric_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  alarm_description   = "Instance or system status check failed (connectivity issues including SSH) for ${each.key}."
  dimensions = {
    InstanceId = each.key
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "network_in" {
  for_each = toset(var.instance_ids)

  alarm_name          = "${var.alarm_name_prefix}-${each.key}-network-in"
  namespace           = "AWS/EC2"
  metric_name         = "NetworkIn"
  statistic           = "Sum"
  period              = var.instance_metric_period_seconds
  evaluation_periods  = var.instance_metric_evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.network_in_threshold_bytes
  alarm_description   = "Inbound network traffic above threshold for ${each.key}."
  dimensions = {
    InstanceId = each.key
  }
  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
}

