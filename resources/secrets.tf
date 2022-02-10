resource "aws_kms_key" "ecs_secrets_key" {
  description             = "KMS key to handling secrets for ECS"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "ecs_secrets_key_alias" {
  name          = "alias/ecs_secrets_key"
  target_key_id = aws_kms_key.ecs_secrets_key.key_id
}

resource "aws_secretsmanager_secret" "ecs_secret" {
  name        = "ecs/test/secret"
  description = "Secret to be injected on container"
  kms_key_id  = aws_kms_key.ecs_secrets_key.key_id
}

resource "aws_secretsmanager_secret_version" "ecs_secret_version" {
  secret_id     = aws_secretsmanager_secret.ecs_secret.id
  secret_string = var.ecs_secret
}
