# TestECS

The objective of this POC is to create all the resources needed to spin up an ECS cluster using Terraform

## Objective description

We want you to create a terraform project for a AWS ECS service which is public accessible using a load balancer.
The service should run two instances of a Docker container which responds on port 80. HTTPS for the load balancer is optional.
Also an environment variables HELLO=world and PASSWORD=secret should be injected into the container for further usage.

## Diagram

## Resources

To achieve this goal we define the following AWS resources
 - AWS
  - aws_alb
  - aws_appautoscaling_policy
  - aws_appautoscaling_target
  - aws_cloudwatch_log_group
  - aws_ecr_repository
  - aws_ecs_cluster
  - aws_ecs_service
  - aws_ecs_task_definition
  - aws_iam_policy
  - aws_iam_role
  - aws_iam_role_policy_attachment
  - aws_kms_alias
  - aws_kms_key
  - aws_lb_listener
  - aws_lb_target_group
  - aws_secretsmanager_secret
  - aws_secretsmanager_secret_version
  - aws_security_group
  - aws_ecs_task_definition
  - aws_iam_policy_document

 - Dockerfile: This file defines the simple services we are going to use to test our app.

## Details

 - We are going to avoid the usage of variables to make the deployment easier, so we are going to use a `locals.tf` file which will allow us to define values for more than one environment.

 - Regarding to environments we are going to define them with terraform `workspaces`, this approach will separate the states of the different envs.

 - The only var we are going to use is `ecs_secret`, this will help us to avoid the storage of a secret on our repo. For a more complex approach we can set and external service to pass this value, like 1password, etc.

## Installation
To deploy the whole environment we need to follow this steps:

### AWS

- 1 - Set your AWS credentials to allow the correct connection to AWS services
```bash
# This will set  the credentials for the default user
$ aws configure
```
  - 1.1 In case you already have AWS credentials you can use that profile doing this:
  ```bash
  # This will set  the credentials for the default user
  $ export AWS_PROFILE=<my-profile>
  ```

- 2 - On the `locals.tf` file define the value for `env_account_id` to explicitly set the account you are going to use for the deploy, and also the `region` to set where we want to deploy the service.

- 3 - Now need to create the workspace, `stage` in this case:
```bash
# By default the creation select the new workspace
# in case you alreay defined it, you can run $ terraform workspace select stage
$ terraform workspace new stage
```

- 4 - Now run a plan to be sure that all the resources are in place to be deployed:
```bash
$ terraform plan --var ecs_secret=<my-secret>
```

- 5 - Once we are sure that everything is in place we can apply the changes:
```bash
$ terraform apply --var ecs_secret=<my-secret>
```


### Docker
To make the image accessible on ECR we can do the following:

 - 1 - Build image
 ```bash
 # We defined this name for the image to make things easier
$ docker build -t testapp-stage-ecr .
```

 - 2 - Connect to ECR
 ```bash
 # We defined this name for the image to make things easier
$ aws ecr get-login-password --region <region>  | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
```

- 3 - Tag image
```bash
$ docker tag testapp-stage-ecr <account_id>.dkr.ecr.<region>.amazonaws.com/testapp-stage-ecr:latest
```

- 4 - Push image
```bash
$ docker push <account_id>.dkr.ecr.<region>.amazonaws.com/testapp-stage-ecr:latest
```

### !! Important, the service will not be available until you do the image push to make it available for the service.
