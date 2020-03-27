#
# With HCL1 it's not possible to add dynamic blocks for the aws_ecs_service resource. For this
# reason many aws_ecs_service's are repeated for their different goals.
#

locals {
  lb_attached = lower(var.load_balancing_type) != "none"
}

# Make an LB connected service dependent of this rule
# This to make sure the Target Group is linked to a Load Balancer before the aws_ecs_service is created
resource "null_resource" "aws_lb_listener_rules" {
  count = var.create ? 1 : 0

  triggers = {
    listeners = join(",", var.aws_lb_listener_rules)
  }
}

resource "aws_ecs_service" "app_with_lb_awsvpc" {
  count = var.create && var.awsvpc_enabled && local.lb_attached && false == var.service_discovery_enabled ? 1 : 0

  name    = var.name
  cluster = var.cluster_id

  task_definition                    = var.selected_task_definition
  desired_count                      = var.desired_capacity
  launch_type                        = var.launch_type
  scheduling_strategy                = var.scheduling_strategy
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  deployment_controller {
    type = var.deployment_controller_type
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets         = var.awsvpc_subnets
    security_groups = var.awsvpc_security_group_ids
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app_with_lb_spread" {
  count = var.create && false == var.awsvpc_enabled && local.lb_attached && var.with_placement_strategy && false == var.service_discovery_enabled ? 1 : 0

  name        = var.name
  launch_type = var.launch_type
  cluster     = var.cluster_id

  task_definition = var.selected_task_definition

  desired_count       = var.desired_capacity
  scheduling_strategy = var.scheduling_strategy

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  deployment_controller {
    type = var.deployment_controller_type
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "memory"
    type  = "binpack"
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app_with_lb" {
  count           = var.create && false == var.awsvpc_enabled && local.lb_attached && false == var.with_placement_strategy && false == var.service_discovery_enabled ? 1 : 0
  name            = var.name
  launch_type     = var.launch_type
  cluster         = var.cluster_id
  task_definition = var.selected_task_definition

  desired_count       = var.desired_capacity
  scheduling_strategy = var.scheduling_strategy

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  deployment_controller {
    type = var.deployment_controller_type
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app" {
  count = var.create && false == local.lb_attached && false == var.awsvpc_enabled && false == var.service_discovery_enabled ? 1 : 0

  name                = var.name
  launch_type         = var.launch_type
  scheduling_strategy = var.scheduling_strategy
  cluster             = var.cluster_id
  task_definition     = var.selected_task_definition

  desired_count = var.desired_capacity

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "app_awsvpc" {
  count = var.create && false == local.lb_attached && var.awsvpc_enabled && false == var.service_discovery_enabled ? 1 : 0

  name                = var.name
  launch_type         = var.launch_type
  scheduling_strategy = var.scheduling_strategy
  cluster             = var.cluster_id
  task_definition     = var.selected_task_definition
  desired_count       = var.desired_capacity

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  network_configuration {
    subnets         = var.awsvpc_subnets
    security_groups = var.awsvpc_security_group_ids
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

### Service Registry resources

locals {
  # service_registries block does not accept a port with "A"-record-type
  # Setting the port to false works through a local
  service_registries_container_port = {
    "SRV" = var.container_port
    "A"   = false
  }
}

resource "aws_service_discovery_service" "service" {
  count = var.create && var.service_discovery_enabled ? 1 : 0

  name = var.name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = var.service_discovery_dns_ttl
      type = var.service_discovery_dns_type
    }

    routing_policy = var.service_discovery_routing_policy
  }

  health_check_custom_config {
    failure_threshold = var.service_discovery_healthcheck_custom_failure_threshold
  }
}

resource "aws_ecs_service" "app_with_lb_awsvpc_with_service_registry" {
  count = var.create && var.awsvpc_enabled && local.lb_attached && var.service_discovery_enabled ? 1 : 0

  name    = var.name
  cluster = var.cluster_id

  task_definition                    = var.selected_task_definition
  desired_count                      = var.desired_capacity
  launch_type                        = var.launch_type
  scheduling_strategy                = var.scheduling_strategy
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets         = var.awsvpc_subnets
    security_groups = var.awsvpc_security_group_ids
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service[0].arn
    container_name = var.container_name
    container_port = local.service_registries_container_port[var.service_discovery_dns_type]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app_with_lb_spread_with_service_registry" {
  count       = var.create && false == var.awsvpc_enabled && local.lb_attached && var.with_placement_strategy && var.service_discovery_enabled ? 1 : 0
  name        = var.name
  launch_type = var.launch_type
  cluster     = var.cluster_id

  task_definition = var.selected_task_definition

  desired_count       = var.desired_capacity
  scheduling_strategy = var.scheduling_strategy

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "memory"
    type  = "binpack"
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service[0].arn
    container_name = var.container_name
    container_port = local.service_registries_container_port[var.service_discovery_dns_type]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app_with_lb_with_service_registry" {
  count           = var.create && false == var.awsvpc_enabled && local.lb_attached && false == var.with_placement_strategy && var.service_discovery_enabled ? 1 : 0
  name            = var.name
  launch_type     = var.launch_type
  cluster         = var.cluster_id
  task_definition = var.selected_task_definition

  desired_count       = var.desired_capacity
  scheduling_strategy = var.scheduling_strategy

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service[0].arn
    container_name = var.container_name
    container_port = local.service_registries_container_port[var.service_discovery_dns_type]
  }

  depends_on = [null_resource.aws_lb_listener_rules]
}

resource "aws_ecs_service" "app_with_service_registry" {
  count = var.create && false == local.lb_attached && false == var.awsvpc_enabled && var.service_discovery_enabled ? 1 : 0

  name                = var.name
  launch_type         = var.launch_type
  scheduling_strategy = var.scheduling_strategy
  cluster             = var.cluster_id
  task_definition     = var.selected_task_definition

  desired_count = var.desired_capacity

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service[0].arn
    container_name = var.container_name
    container_port = local.service_registries_container_port[var.service_discovery_dns_type]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "app_awsvpc_with_service_registry" {
  count = var.create && false == local.lb_attached && var.awsvpc_enabled && var.service_discovery_enabled ? 1 : 0

  name                = var.name
  launch_type         = var.launch_type
  scheduling_strategy = var.scheduling_strategy
  cluster             = var.cluster_id
  task_definition     = var.selected_task_definition
  desired_count       = var.desired_capacity

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_controller {
    type = var.deployment_controller_type
  }

  network_configuration {
    subnets         = var.awsvpc_subnets
    security_groups = var.awsvpc_security_group_ids
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.service[0].arn
    container_name = var.container_name
    container_port = local.service_registries_container_port[var.service_discovery_dns_type]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

