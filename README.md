<div align="center">
    <a href="https://www.docker.com/">
        <img src="https://user-images.githubusercontent.com/46251023/141686972-bf7654f6-681b-4ac0-ae2d-0aab05c654a9.png" />
    </a>
    <a href="https://aws.amazon.com/">
        <img src="https://user-images.githubusercontent.com/46251023/141667289-95911bbd-8754-455a-a253-9067d7e8d3b5.png" />
    </a>
    <a href="https://www.terraform.io/">
        <img src="https://user-images.githubusercontent.com/46251023/141687204-6ee73196-a43c-4465-9895-0e85e9c0ad82.png" />
    </a>
</div>

<div align="center">
    <a href="https://laravel.com/">
        <img src="https://user-images.githubusercontent.com/46251023/141667288-58891a2a-71b0-4ce7-8f6a-0a85f8230b4e.png" />
    </a>
    <a href="https://nuxtjs.org/">
        <img src="https://user-images.githubusercontent.com/46251023/141667291-8852e114-a7c5-4993-82cd-6c3867cd33b9.png" />
    </a>
</div>

# Laravel + Vue + Terraform

Sample containerized nuxt-laravel project on AWS with terraform.

## Architecture

![Architecture diagram](https://user-images.githubusercontent.com/46251023/147506043-215795c7-fea1-432e-9260-06413acedf23.png)

The project consists of a containerized Laravel + NuxtJS [three-tier architecture](https://docs.aws.amazon.com/whitepapers/latest/serverless-multi-tier-architectures-api-gateway-lambda/three-tier-architecture-overview.html) running on ECS Fargate on top of VPC subnets across two availability zones.

Each Laravel task runs an Nginx container that forwards traffic to another container running a PHP FPM process. For Nuxt SSR to work, frontend tasks require access to backend instances. This is solved with Route53 and CloudMap for service discovery by configuring the backend's ECS service to automatically register all tasks to Route53 under a friendly DNS name that is later injected as an environment variable into frontend tasks to communicate with them.

The Application Load Balancer handles incoming internet requests and forwards them to the appropriate target group tasks. Any request path that starts with `/api/` is forwarded to the backend's target group, any other path ends in the frontend's.

NAT gateway gets created inside a public subnet to provide backend tasks and RDS internet access while in private subnets.

The CI/CD flow starts with a new code push to the repository's master branch, which triggers a new CodePipeline release via webhook. The CodePipeline steps are as follows:

1. Fetch and store the repository's source code in an S3 bucket.
1. Start two CodeBuild processes for building the frontend and backend's docker images and push them into their respective ECR repositories.
1. Start two new CodeBuild processes for initializing ECS deployments with the new frontend and backend images.
1. ECS updates each ECS service with the new images and executes a rolling deployment strategy to ensure zero downtime.

## Set up

### Local environment

1. Run `cd frontend`
1. Run `cp .env.example .env`

1. Run `cd ../backend`
1. Run `cp .env.example .env`
1. Run `docker-compose up`
1. Run `docker-compose exec backend composer install`
1. Run `docker-compose exec php artisan key:generate`

1. Check the app running at http://localhost:3000. You should see the following screen:
   ![Nuxt screen](https://user-images.githubusercontent.com/46251023/147396029-d5eb0ebb-1b73-43d3-89b3-7682a628dfad.png)

### Cloud environment

1. [Install terraform cli](https://learn.hashicorp.com/tutorials/terraform/install-cli).

1. Run `cd terraform`
1. Run `cp terraform.tfvars.example terraform.tfvars`

1. Login into AWS account and create a user with programmatic access and attach the Administrator access policy (arn:aws:iam::aws:policy/AdministratorAccess). This user will be used by Terraform to provision infrastructure.
   Copy the access key ID and secret access key and paste them into terraform.tfvars and then fill in the other variables.

1. Run `terraform init` to download dependencies.

1. Run `terraform apply --auto-approve` and wait a few minutes until all resources are successfully created. Take note of the `alb_dns_name` output once the apply is finished.

1. Go to Codepipeline->Settings->Connections on AWS console or follow [this link](https://console.aws.amazon.com/codesuite/settings/connections). Click on the recently created Github connection that is currently pending, and then click on "Update pending connection" to allow access to the Github repository.

1. Find the recently created pipeline that should be in a "Failed" state because it started executing without the Github connection being approved by clicking on either the backend or frontend service and then going to the "Deployment" tab.

1. Wait for the pipeline to finish. You can see the status of the deployment through the ECS cluster [here](https://console.aws.amazon.com/ecs) and clicking any of the backend or frontend services and then going to the "Deployment" tab.

1. Once the deployment finishes, enter the value of `alb_dns_name` that you noted earlier into the browser, and you should see the base NuxtJS landing page with a message below that says "Response: DB connected", which means that Laravel was able to connect to the RDS database. The response was rendered server-side, so it means that the frontend task was also able to communicate with a backend task.

1. To delete resources, run `terraform destroy --auto-approve` and once the destroy is completed, delete the user that you previously created.
