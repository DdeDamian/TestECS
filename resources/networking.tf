# -------------------------------------------------------------
# AWS VPC and subnets
# -------------------------------------------------------------

module "vpc" {
  # We will be using community modules to keep them up-to-date
  source = "terraform-aws-modules/vpc/aws"

  name            = local.vpc_name[terraform.workspace]
  cidr            = local.vpc_cidr[terraform.workspace]
  azs             = local.azs[terraform.workspace]
  public_subnets  = local.public_subnets_cidrs[terraform.workspace]
  private_subnets = local.private_subnets_cidrs[terraform.workspace]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
  }
}

# -------------------------------------------------------------
# LoadBalancing resources & Security Groups
# -------------------------------------------------------------

resource "aws_alb" "application_load_balancer" {
  name               = "${local.app_name}-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name        = "${local.app_name}-alb"
    Environment = terraform.workspace
  }
}

resource "aws_security_group" "service_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${local.app_name}-service-sg"
    Environment = terraform.workspace
  }
}


resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${local.app_name}-lb-sg"
    Environment = terraform.workspace
  }

  depends_on = [module.vpc]

}

resource "aws_lb_target_group" "target_group" {
  name        = "${local.app_name}-${terraform.workspace}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/v1/status"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${local.app_name}-lb-tg"
    Environment = terraform.workspace
  }

  depends_on = [module.vpc]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}
