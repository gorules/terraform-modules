resource "aws_cloudwatch_metric_alarm" "brms_cpu_high" {
  count = local.create_brms ? 1 : 0

  alarm_name          = "${var.name_prefix}-brms-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "BRMS ECS service CPU utilization is above 80%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.brms[0].name
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "brms_memory_high" {
  count = local.create_brms ? 1 : 0

  alarm_name          = "${var.name_prefix}-brms-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "BRMS ECS service memory utilization is above 80%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.brms[0].name
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-memory-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "brms_alb_5xx" {
  count = local.create_brms ? 1 : 0

  alarm_name          = "${var.name_prefix}-brms-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "BRMS ALB is returning more than 10 5xx errors per minute"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.brms[0].arn_suffix
    TargetGroup  = aws_lb_target_group.brms[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-alb-5xx"
  })
}

resource "aws_cloudwatch_metric_alarm" "brms_unhealthy_targets" {
  count = local.create_brms ? 1 : 0

  alarm_name          = "${var.name_prefix}-brms-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "BRMS has unhealthy targets in the target group"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.brms[0].arn_suffix
    TargetGroup  = aws_lb_target_group.brms[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-unhealthy-targets"
  })
}

resource "aws_cloudwatch_metric_alarm" "agent_cpu_high" {
  count = local.create_agent ? 1 : 0

  alarm_name          = "${var.name_prefix}-agent-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Agent ECS service CPU utilization is above 80%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.agent[0].name
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "agent_memory_high" {
  count = local.create_agent ? 1 : 0

  alarm_name          = "${var.name_prefix}-agent-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Agent ECS service memory utilization is above 80%"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.agent[0].name
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-memory-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "agent_alb_5xx" {
  count = local.create_agent ? 1 : 0

  alarm_name          = "${var.name_prefix}-agent-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Agent ALB is returning more than 10 5xx errors per minute"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.agent[0].arn_suffix
    TargetGroup  = aws_lb_target_group.agent[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-alb-5xx"
  })
}

resource "aws_cloudwatch_metric_alarm" "agent_unhealthy_targets" {
  count = local.create_agent ? 1 : 0

  alarm_name          = "${var.name_prefix}-agent-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Agent has unhealthy targets in the target group"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = aws_lb.agent[0].arn_suffix
    TargetGroup  = aws_lb_target_group.agent[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-unhealthy-targets"
  })
}
