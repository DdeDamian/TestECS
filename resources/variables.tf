# -------------------------------------------------------------
# Variables definition
# -------------------------------------------------------------

variable "ecs_secret" {
  description = "Secret to be injected on ECS service"
  type        = string
}
