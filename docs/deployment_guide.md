# Requirements
Before you deploy, you must have the following in place:
*  [AWS Account](https://aws.amazon.com/account/) 
*  [GitHub Account](https://github.com/) 
*  [Node 10 or greater](https://nodejs.org/en/download/) 
*  [Amplify CLI installed and configured](https://aws-amplify.github.io/docs/cli-toolchain/quickstart#quickstart) 

For prototyping, you need the following:
*  [Python 3.7 or greater](https://realpython.com/installing-python/) 
*  [SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) 
*  [Docker](https://docs.docker.com/install/) 


# Step 1: Front-end deployment

1.  Clone and Fork this solution repository.
    If you haven't configured Amplify before, configure the Amplify CLI in your terminal as follows:
```bash
amplify configure
```

2.  In a terminal from the project root directory, enter the following command selecting the IAM user of the AWS Account you will deploy this application from. (accept all defaults):

```bash
amplify init
```

3.  Deploy the resourse to your AWS Account using the command:
```bash
amplify push
```

4.  After the Amplify deployment finishes, run the command bellow to obtain the Amazon S3 Bucket Amplify created. This information will be used later as a parameter in a clouformation
```bash
aws resourcegroupstaggingapi get-resources --tag-filters Key=user:Application,Values="COVID19L3NetAPP" Key=user:Stack,Values="dev" --resource-type-filters s3 --query 'ResourceTagMappingList[*].[ResourceARN]' --output text | grep -v deployment | awk -F':::' '{print $2}'
```

5. Log into the AWS Management Console.
6. Select AWS Amplify and select the COVID19L3NetApp
7. At the *Frontend environments* tab connect to your github account poiting to the forked repo. More informatoin at https://docs.aws.amazon.com/amplify/latest/userguide/deploy-backend.html

# Step 2: Back-end deployment

In this step we will execute three Cloudformation scripts:
* [cfn-vpc](../cfn/cfn-vpc.yaml) - This Cloudformation create the networking for the image creation EC2 instance, Lambda functions and EC2 instances that processes the model.
* [cfn-imageBuilder](../cfn/cfn-imageBuilder.yaml) - It creates the EC2 Image Builder infrastructure that embeds the model into our custom AMI. 
* [cfn-backend](../cfn/cfn-backend.yaml) - Responsible for the creation of the underlying infrastrucutre of the solution. It includes the EC2 Auto Scaling configuration, SQS, VPC Endpoints, EFS and CloudFront


## Step 2.1: VPC

1. Log into the CloudFormation Management Console.
2. Select Create stack with the With new resources option.
3. Click Upload a template file, and then Choose file and select the **cfn-vpc.yaml** located at the /cfn directory of the repo
4. Click Next.
5. Give the Stack name a name (e.g. covid-19-app-vpc).

## Step 2.2: EC2 Image Builder

1.  You also need the latest Deep Learning Amazon Machine Image (AMI) Id in the step. Please, run the command bellow to obtain it. **Make sure run this command on the region you are executing the solution.**
```bash
aws ec2 describe-images \
    --owners amazon \
    --filters 'Name=name,Values=Deep Learning Base AMI (Amazon Linux 2)*' 'Name=state,Values=available' \
    --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' \
    --output text
```

2. Log into the CloudFormation Management Console.
3. Select Create stack with the With new resources option.
4. Click Upload a template file, and then Choose file and select the **cfn-ImageBuilder.yaml** located at the /cfn directory of the repo
5. Click Next.
6. Give the Stack name a name (e.g. covid-19-app-ImageBuilder).
7. Select a key-pair. If you don’t have any Amazon EC2 key-pair available [create-your-key-pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair), and repeat this step.
8. On the AmazonLinuxAMI paste the AMI ID from the command listed at begining of thid step.

:warning: **Important Note**: This step takes approximatelly 40min-60min as it spins up an instance and runs all the steps to create the AMI. **Make sure it finishes succesfully to move to the next step**

## Step 2.3: Backend

1. Log into the CloudFormation Management Console.
2. Select Create stack with the With new resources option.
3. Click Upload a template file, and then Choose file and select the **cfn-backend.yaml** located at the /cfn directory of the repo
4. Click Next.
5. Give the Stack name a name (e.g. covid-19-app-ImageBuilder).
6. Select a key-pair that you have defined on Step 2.1 item 7.
7. On the S3Bucket field past the bucket name obtained on the step 1.


# Step 3: Lambda Function

## 3.1: Creating the Pydicom Layer
When a CT-Scan is submitted to be processed, a Lambda function is triggered to make sure that all files within the ZIP file are DICOM files. For this verification we leverage [Pydicom](https://pydicom.github.io/).  The first step to get this Lambda Function implemented is to create the Layer file. 

1. Go to the directory <strong>/backend/lambda</strong> and execute:
```bash
deploy.sh 
```

This command launches a series of action that includes running a docker to retrieve Pydicom and create the layer file to be used on the lambda function.


