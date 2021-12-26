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

# Terraform sample

The scope for this project is to configure a containerized working environment for a fullstack nuxt-laravel app on AWS using terraform as IaC tool.

## Arquitecture

![AWS diagram](https://user-images.githubusercontent.com/46251023/147390495-2ca8a472-0e22-449a-9cd5-b3973bc01a7c.png)

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

1. Log into AWS account and create a user with programatic access and attach the Administrator access policy (arn:aws:iam::aws:policy/AdministratorAccess). This user will be used by terraform to provision infrastructure.
   Copy the access key ID and secret access key and paste it into terraform.tfvars and then fill the other variables.

1. Run `terraform init` to download dependencies.

1. Run `terraform apply --auto-approve` and wait a couple of minutes until all resources are successfully created. Notice the `alb_dns_name` outputed once the apply finished.

1. Go to Codepipeline->Settings->Connections or follow [this link](https://console.aws.amazon.com/codesuite/settings/connections), click the recently created github connection that is currently pending. Once inside click on "Update pending connection" and allow access to the github repository.

1. Find the recently created pipeline that should be in "Failed" state because it started executing without the github connection approved, and start a new release.

1. Wait for the de pipeline to finish. You can see the process of the deployment through the ecs cluster [here](https://console.aws.amazon.com/ecs) and clicking any of the backend or frontend services and then going to the "Deployment" tab.

1. Once the deployment finished, enter the value of `alb_dns_name` on the browser and you should see the base NuxtJS landing page with a message below that says "Response: DB connected" which means that laravel was able to connect to the RDS database. The response was rendered server side so it means that the frontend task was able to communicate with a backend task.

1. Clear resources by running `terraform destroy --auto-approve` and once the destroy is complete delete the user previously created.

## Costs

Coming soon

<!-- A nice thing about ECS when compared to Kubernetes hosting on AWS using EKS is that ECS does't have a fixed cost for having a cluster running.

https://calculator.aws/#/estimate?id=38773fa7a4cdfee5423039d579ecbb64049a619a -->

## Next steps

#### 1. Include DB migration flow

Whenever there is a new version that includes new migration files, those should be run somewhere along the pipeline.
Things to discuss here are the when, where and how.

##### When

Let's consider here a scenario where a new version of the app has just been pushed and it includes a new feature improvement that implied a breaking change migration, this means that the migration and the new changes are mutually dependant so if possible, the deploy should be done the most atomically as possible where there should never exist a system snapshot where the new migration successfully took place but the feature deployment didn't, or viceversa. Otherwise, the system could be in a mixed and inconsistant state having half of the new changes coexisting with the previous (currently deployed) version. This could mean that the old feature code was previously working on top of its expected database schema but has now been updated without the code taking notice, or in the other way around, the feature code was correctly deployed and is now running but it assumes the database has a certain schema where in reallity it does't due to having the migration currently in progress or even worse, having failed.

So in essence, which one goes first, migrations or code deployment?
Migrations are risky and prone to fail due to any possible environment specific reason, so having the deployment first would risk the migration failing and falling into the second example above.
Having the migration first is the other option but as soon as the migration completes and the code is deploying, the currently deployed containers will break as shown in the first example above. The inconsistant state will also last longer if executing a strategy like rolling deployment where all instances are not immediately updated so the whole process would be inconsistant until the last instance finally gets the new version.
Based on my investigation, people seem to like the former one the most, where in the case there must be a breaking change migration, a new coder version should be deployed previously to make the app work in both the old in the old schema and in the new one. Which would solve the issue stated.

#### Where & How

Where should migrations by run? In codebuild? The issue is that the migration should be run from inside a laravel container. What if the container has many other dependencies? should codebuild know how to build the complete environment including having DB credentials? Sounds wrong IMO.
Maybe a good idea would be something like starting a temporal task with the new code from codebuild that runs migrations and exits.

#### 2. Find solution for laravel's scheduler and queue workers (harder than it looks)

Laravel provides ways for managing [queue](https://laravel.com/docs/8.x/queues#dispatching-jobs) events and [scheduling](https://laravel.com/docs/8.x/scheduling) tasks to be run every given time and I find them really useful.
Based on the problems I had, I found both queue and scheduler have their own independent issues, so I should each one deserves a subtitle on its own.

##### Queue workers

In the regular 1 compute instance approach where there is only a single instance (say EC2) running the application, it's easy to run the commands that start both queue and scheduler respectively which start new processes for handling their responsibilities (processing queue events and running chron scheduler). However, in the context of containers where the best approach is having a single process inside a container, that means that you can't run the main PHP (laravel) process together with a scheduler or queue task-running process because that would require 2 running processes inside the same container.

I'm aware that there are ways of fighting the way into having multiple processes in the same container with tools like supervisord but I didn't like how that sounded and it also hurts the horizontal scalling capabilities as now the queue workers processing power becomes dependant on how many laravel servers are running. Imagine that you have a small app that works with lots of events. The only way of increasing the compute power of the queue workers would be to add new instances, but that comes together with a new laravel installation with its own copy of the API you created, scheduler and who knows what other features you are not interesting in boosting. Remember you just needed to have more queue workers.
On the other hand you could have an enormous app that hardly emits events and having queue workers on each container would be a waste of resources.

The previous idea makes me believe the ideal solution would be to scale the queue workers in their own specialized containers and adjust the number of running containers accordingly. With how easy and fast it is to create new containers on ECS, it could also be possible to scale them (out or in) on demand based on how many events are currently queued (great for costs). The issue of having workers live in their own containers is they also need to have the complete source code in them, summing up to a lot of memory together with the regular laravel instances you are going to be paying.

##### Task scheduling

The main difference between task scheduling and queue workers is that queue workers are designed to work in fleets, so there's no issue on having many workers pulling events from the same event queue as with a properly configured queue, there are [not going to be multiple workers processing the same event](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html).

Having the same solution would imply the possibility of running multiple task schedulers in paralel which cannot happen because as opposed to events that are taken from a centrilized pool, schedulers are run idependently on each instance so every task would be run the same amount of times as instances running, which is not desired.

I've encountered a work around for this and worked by having a dummy container whose only responsibility is to make an API call to an endpoint of a random service discovered backend instance every minute and the chosen instance then takes care of executing the scheduler internally.
Looking at Kubernetes forms, some people claimed to start a new pod every minute that runs the scheduler and the exits but I've found some of them retracting from the idea as it genereted "too much noise" from all the logs of firing up new pods every minute.

#### 3. Add bastion host to access DB

In most cases, it's useful to have access (at least read) to the production database from a personal machine in order to easily debug and analyze the actual data. However, having the database inside a private subnet means that there is no way of connecting to it through the internet. A bastion host is an instance (EC2) that sits on a public subnet so anyone with the correct keys can ssh into it, that has direct access (through VPC) and it's used as a jump server for the database instances.
There are many articles online both oficial and unoficial for implementing it through Terraform or Cloudformation.

#### 4. Move terraform infrastructure applies to cloud

At the moment, regarding Terraform changes (applies), this project is designed to be run and maintained from a local pc. Would be great offload responsibility to the actual pipeline flow once the new Terraform changes have been pushed, instead of having to apply changes locally and then push the code just for the sake of wanting it to be version controlled.
There are great articles out there that everytime the pipeline runs, `terraform plan` command is executed and whenever terraform suggests changes, a manual approval is required to confirm the apply and modify the current infrastructure, everything taken care from the pipeline ui interface.

#### 5. Multi env (staging environment)

The project works with a single environment. Would be great to bring a staging environment into the flow to test out infrastructure changes before going into production.
