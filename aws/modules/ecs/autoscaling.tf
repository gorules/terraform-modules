resource "aws_appautoscaling_target" "brms" {
  count = local.create_brms ? 1 : 0

  max_capacity       = var.brms.max_count
  min_capacity       = var.brms.min_count
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.brms[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "brms_cpu" {
  count = local.create_brms ? 1 : 0

  name               = "${var.name_prefix}-brms-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.brms[0].resource_id
  scalable_dimension = aws_appautoscaling_target.brms[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.brms[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.brms.cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "agent" {
  count = local.create_agent ? 1 : 0

  max_capacity       = var.agent.max_count
  min_capacity       = var.agent.min_count
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.agent[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "agent_cpu" {
  count = local.create_agent ? 1 : 0

  name               = "${var.name_prefix}-agent-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agent[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agent[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agent[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.agent.cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
