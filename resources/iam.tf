# Policy to allow ECR pull
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Policy to allow secrets handling
data "aws_iam_policy_document" "secret_handling" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]

    resources = [
      "${aws_secretsmanager_secret.ecs_secret.arn}",
      "${aws_kms_key.ecs_secrets_key.arn}"
    ]
  }
}

# Policies creation
resource "aws_iam_policy" "secret_handling_policy" {
  name        = "secret_handling_policy"
  path        = "/"
  description = "Allows secrets handling"
  policy      = data.aws_iam_policy_document.secret_handling.json
}

resource "aws_iam_role" "ecs_etr" {
  name               = "${local.app_name}-etr"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${local.app_name}-iam-role"
    Environment = terraform.workspace
  }
}

# Policies attachments
resource "aws_iam_role_policy_attachment" "ecs_etr_policy" {
  role       = aws_iam_role.ecs_etr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "secrets_etr_policy" {
  role       = aws_iam_role.ecs_etr.name
  policy_arn = aws_iam_policy.secret_handling_policy.arn
}
