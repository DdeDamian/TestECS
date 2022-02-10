# -------------------------------------------------------------
# ECS Cluster
# -------------------------------------------------------------

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${local.app_name}-${terraform.workspace}-cluster"

  tags = {
    Name        = "${local.app_name}-ecr"
    Environment = terraform.workspace
  }
}

# -------------------------------------------------------------
# ECS Service
# -------------------------------------------------------------

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${local.app_name}-${terraform.workspace}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${local.app_name}-${terraform.workspace}-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.aws-ecs-cluster.name}/${aws_ecs_service.aws-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# -------------------------------------------------------------
# ECS Auto scaling policies
# -------------------------------------------------------------

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${local.app_name}-${terraform.workspace}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${local.app_name}-${terraform.workspace}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

# -------------------------------------------------------------
# Fargate task definition
# -------------------------------------------------------------

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${local.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${local.app_name}-${terraform.workspace}-container",
      "image": "${aws_ecr_repository.aws-ecr.repository_url}:latest",
      "entryPoint": [],
      "environment": [
        {
          "name": "HELLO",
          "value": "world"
        }
      ],
      "secrets": [
        {
          "name": "PASSWORD",
          "valueFrom": "${aws_secretsmanager_secret.ecs_secret.arn}"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${local.region[terraform.workspace]}",
          "awslogs-stream-prefix": "${local.app_name}-${terraform.workspace}"
        }
      },
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_etr.arn
  task_role_arn            = aws_iam_role.ecs_etr.arn

  tags = {
    Name        = "${local.app_name}-ecs-td"
    Environment = "${terraform.workspace}"
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}
