# AWSClusterManagersDemo.jl
## Overview
This demo project was presented at JuliaCon2021 to showcase a minimal example of the [AWSClusterManagers.jl](https://github.com/JuliaCloud/AWSClusterManagers.jl) package on AWS Batch. The job submitted to Batch calculates the approximate value of PI. The explanation for this can be found in this [article](https://jccraig.medium.com/calculate-pi-with-a-dartboard-bdb433f1c999).

The job will:
1. Launch four worker nodes
2. Have each worker run a small process
3. Retrieve and combine the results
4. Display the results to CloudWatch logs
## Setup
**Note: When running this package you will be responsible for all AWS charges in your account.**
On-Demand instances at the time of writing are charged on a per-minute basis. An estimated cost for running the demo project and immediately destroying the stacks is around `$0.50 USD`.

To launch this yourself:

1. Store your AWS account ID in an variable
   	`AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`
1. Create a new ECR (Elastic Cloud Registry) repository to host you Docker image as:
    `aws cloudformation create-stack --template-body file://ecr_template.yml --stack-name awsclustermanagers-ecr`
2. Build the Docker image for this project
    `docker build -t $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/awsclustermanagers-demo:latest .`
3. Push the Docker image to the ECR repo created in the second step
    `docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/awsclustermanagers-demo:latest`
1. Deploy the remainder of the Batch resources required to run the demo
    `aws cloudformation create-stack --template-body file://batch_template.yml --stack-name awsclustermanagers-batch`
1. Submit your job to AWS Batch!
    `aws batch submit-job --job-name aws-batch-demo --job-definition AWSClusterManagersDemo-Job --job-queue awsclustermanagers-demo`
1. To view the results simply run
    `STREAM_NAME=$(aws logs describe-log-streams --log-group-name /aws/batch/job --query logStreams[1].logStreamName --output text)`
    `aws logs get-log-events --log-group-name /aws/batch/job --log-stream-name $STREAM_NAME --output text`

## Teardown

1. Deleting the Batch stack is simply:
    `aws cloudformation delete-stack --stack-name awsclustermanagers-batch`
1. Deleting the ECR stack is slightly more complex
    1. First we need to remove all images from the ECR repo by running:
        `IMAGES_TO_DELETE=$( aws ecr list-images --repository-name awsclustermanagers-demo --filter "tagStatus=ANY" --query 'imageIds[*]' --output json )`
        `aws ecr batch-delete-image --repository-name awsclustermanagers-demo --image-ids "$IMAGES_TO_DELETE"`
    1. We can then delete the ECR stack by running:
        `aws cloudformation delete-stack --stack-name awsclustermanagers-ecr`
