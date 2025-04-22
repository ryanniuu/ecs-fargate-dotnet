# build sample .NET8 application

dotnet new hello-dotnet
cd hello-dotnet
dotnet publish --os linux --arch arm64 /t:PublishContainer

https://github.com/aws-observability/aws-otel-community/blob/master/sample-apps/dotnet-sample-app/README.md
dotnet run

podman build --platform linux/arm64 -t dotnet-sample .
podman run  -p 8080:8080 dotnet-sample

aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 495677365376.dkr.ecr.ap-southeast-2.amazonaws.com
remove ~/.docker/docker.config file

docker build -t dotnet-sample .
docker tag dotnet-sample:latest 495677365376.dkr.ecr.ap-southeast-2.amazonaws.com/dotnet-sample:latest
docker push 495677365376.dkr.ecr.ap-southeast-2.amazonaws.com/dotnet-sample:latest

podman push 495677365376.dkr.ecr.ap-southeast-2.amazonaws.com/dotnet-sample:latest

aws ecs update-service --cluster dotnet-sample-dev --service dotnet-sample-dev-tenant1  --desired-count 3
aws ecs describe-services --cluster dotnet-sample-dev --services dotnet-sample-dev-tenant1
aws ecs update-service --cluster dotnet-sample-dev --service dotnet-sample-dev-tenant1 --force-new-deployment

### Check service events
aws ecs describe-services --cluster dotnet-sample-dev --services dotnet-sample-dev-tenant1
### Get the failed task's details
aws ecs list-tasks --cluster dotnet-sample-dev --service dotnet-sample-dev-tenant1 --desired-status STOPPED
### Get detailed task information including stop reason
aws ecs describe-tasks --cluster dotnet-sample-dev --tasks <task-id-from-above>
### Configure Circuit Breaker and Rollback:
aws ecs update-service --cluster dotnet-sample-dev --service dotnet-sample-dev-tenant1 \
    --deployment-configuration \
    "deploymentCircuitBreaker={enable=true,rollback=true}"
### Temporarily disable circuit breaker if needed:
aws ecs update-service \
    --cluster dotnet-sample-dev \
    --service dotnet-sample-dev-tenant1 \
    --deployment-configuration \
    "deploymentCircuitBreaker={enable=false,rollback=false}"
### Force new deployment after fixes:
aws ecs update-service \
    --cluster dotnet-sample-dev \
    --service dotnet-sample-dev-tenant1 \
    --force-new-deployment

# Q Prompts

Prompt-1
/dev I am creating a sample application that does following:
1/ it is deployed into a AWS ECS using Fargate
2/ it is a .net core application based on container image mcr.microsoft.com/dotnet/samples:latest; an ECR repo should be created and use the ECR repo in the ECS task definition 
3/ it uses AWS RDS SQL Server as database layer and may connects to multiple RDS instances dynamicly
4/ it uses Tarraform as IaaS provisioning tool
5/ it creates multiple ECS services with different node and scaling configurations from same code base (the container image mcr.microsoft.com/dotnet/samples:latest) 
6/ it has ALB at front to route incoming traffic based on sub-domains, with root domain https://definitiv.com.au/;  https://tenant1.definitiv.com.au/ goes to  ECS service tenant1 which connects to RDS SQL Server database tenant1, and  https://definitiv.com.au/ goes to  ECS service tenant2 which connects to RDS SQL Server database tenant2.
7/ it uses AWS Graviton-based compute with AWS Fargate Spot in ECS.
8/ it has AWS Distro for Open Telemetry installed and configured to be able to stream the logs and metrics to New Relic
9/ the container image should be stored in ECR
10/ use http rather than https for now
11/ use AWS Secrets Manager to store sensitive data such as Database passwords
12/ add a git ignore file and add below items: .git .terraform .terraform.lock.hcl
13/ add a README for the project
14/ the .net application listens on port 8080, so please set aws ecs deployments to take incoming traffic at port 80 at load balancer, and forward to ecs services and containers listening on port 8080

Please create this application for me with detailed deployment code, including the VPC, ECS and services, Dockerfile, ECR repo, RDS, ALB and AWS Distro for Open Telemetry, all using Terraform codes.

Please create the files recommended in current folder

Prompt-2
Generate devfile to build code


### 
manually replace AWS Distro for OpenTelemetry Collector URL in Dockerfile to 
https://aws-otel-collector.s3.amazonaws.com/ubuntu/amd64/latest/aws-otel-collector.deb

### dotnet sample container
https://github.com/dotnet/dotnet-docker/blob/main/samples/dotnetapp/README.md


# Building and Pushing Container Images to ECR

To build and push your container image to Amazon ECR, follow these steps:

1. **Authenticate to Amazon ECR:**
```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.<your-region>.amazonaws.com
```

2. **Build the Docker image:**
```bash
## docker build -t <image-name> .
docker buildx build --platform linux/arm64 -t your-image-name:arm64 .
```

3. **Tag your image for ECR:**
```bash
docker tag <image-name>:latest <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/<repository-name>:latest
```

4. **Push the image to ECR:**
```bash
docker push <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/<repository-name>:latest
```

Replace the placeholders:
- `<your-region>`: Your AWS region (e.g., us-east-1)
- `<your-account-id>`: Your AWS account ID
- `<image-name>`: Local name for your Docker image
- `<repository-name>`: Name of your ECR repository

Note: Make sure you have:
- AWS CLI installed and configured with appropriate credentials
- Docker installed and running on your machine
- Required permissions to push to ECR


Outputs:

alb_dns_name = "dotnet-sample-dev-199949252.ap-southeast-2.elb.amazonaws.com"
ecr_repository_url = "495677365376.dkr.ecr.ap-southeast-2.amazonaws.com/dotnet-sample"
rds_endpoints = <sensitive>


