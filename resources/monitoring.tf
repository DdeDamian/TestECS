resource "aws_cloudwatch_log_group" "log-group" {
  name = "${local.app_name}-${terraform.workspace}-logs"

  tags = {
    Name        = "${local.app_name}-ecr"
    Environment = terraform.workspace
  }
}
