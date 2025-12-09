module "monitoring" {
  source = "./terraform/monitoring"

  vpc_id       = aws_vpc.KCVPC.id
  instance_ids = [
    aws_instance.Publicweb_server.id,
    aws_instance.PrivateDB_server.id,
  ]

  alarm_name_prefix          = var.monitoring_alarm_name_prefix
  create_sns_topic           = var.monitoring_create_sns_topic
  existing_sns_topic_arn     = var.monitoring_existing_sns_topic_arn
  alarm_email_addresses      = coalesce(
    length(var.monitoring_alarm_email_addresses) > 0 ? var.monitoring_alarm_email_addresses : null,
    ["wisdom.ugwoh@gmail.com"]
  )
  cpu_high_threshold         = var.monitoring_cpu_high_threshold != 0 ? var.monitoring_cpu_high_threshold : 85
  network_in_threshold_bytes = var.monitoring_network_in_threshold_bytes != 0 ? var.monitoring_network_in_threshold_bytes : 209715200 # 200 MB
}

