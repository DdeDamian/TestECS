resource "aws_ecr_repository" "aws-ecr" {
  name = "${local.app_name}-${terraform.workspace}-ecr"

  tags = {
    Name        = "${local.app_name}-ecr"
    Environment = terraform.workspace
  }
}
