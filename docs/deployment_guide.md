# Requirements
Before you deploy, you must have the following in place:
*  [AWS Account](https://aws.amazon.com/account/) 
*  [GitHub Account](https://github.com/) 
*  [Node 10 or greater](https://nodejs.org/en/download/) 
*  [Amplify CLI 4.13.1 or greater installed and configured](https://aws-amplify.github.io/docs/cli-toolchain/quickstart#quickstart) 

For prototyping, you need the following:
*  [Python 3.7 or greater](https://realpython.com/installing-python/) 
*  [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) 
*  [Docker](https://docs.docker.com/install/) 


# Step 1: Deploy the SQS and EC2 infrastructure
In this step, we will deploy all the base back-end infrastructure to process the images as they land on S3. 

1. Clone the repo.
2. Log into the  [CloudFormation Management Console](https://console.aws.amazon.com/cloudformation/home) .
3. Select **Create stack** with the _With new resources_ option.
4. Click _Upload a template file_, and then **Choose file** and select the <strong>backend/sqs-ec2/sqs-ec2-asg.yaml</strong>
5. Click _Next_.
6. Give the **Stack name** a name (e.g. **l3backend**). Select a key-pair and leave all the other fields with the default values. If you don’t have any Amazon EC2 key-pair available  [Create-your-key-pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair) , and repeat this step.
7. Click Next twice. Don’t forget to check the checkbox for **I acknowledge that AWS CloudFormation might create IAM resources.** as the cloudformation creates a role for the EC2 instance that grants you access to all resources/services required during the workshop.

📓 **Note**: While the stack is deploying, which takes approximately ~5 minutes to finish, we carry on to the next step.

# Step 2: Deploy the Lambdas


