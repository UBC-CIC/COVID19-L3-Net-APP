#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"

# ${sqsUrl} ${logGroup} ${cloudfrontDomain} ${gitBranch}

SQSQUEUE=$1
CLOUDWATCHLOGSGROUP=$2
CLOUDFRONT=$3
GITBRANCH=$4

WORKING_DIR=/root/covid-19-app-${GITBRANCH}/backend/sqs-ec2

logger "$0: -------------- Initializing user-data.sh Account: ${ACCOUNT} - Region: ${REGION} - Queue: ${SQSQUEUE} - Logs: ${CLOUDWATCHLOGSGROUP} - CDN: ${CLOUDFRONT} - Branch: ${GITBRANCH}"

yum -y --security update
yum -y update aws-cli

# This fixes awslogsd.service error (ImportError: cannot import name _normalize_host)
pip install --user sphinx

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf
sed -i "s|%CLOUDWATCHLOGSGROUP%|$CLOUDWATCHLOGSGROUP|g" /etc/awslogs/awslogs.conf

systemctl start amazon-ssm-agent
systemctl start awslogsd

sed -i "s|%REGION%|$REGION|g" /usr/local/bin/worker.sh
sed -i "s|%SQSQUEUE%|$SQSQUEUE|g" /usr/local/bin/worker.sh
sed -i "s|%WORKING_DIR%|$WORKING_DIR|g" /usr/local/bin/worker.sh
sed -i "s|%CLOUDFRONT%|$CLOUDFRONT|g" /usr/local/bin/worker.sh

if [[ "${GITBRANCH}" == "master" ]]; then
   IMAGE_TAG="latest"
else
   IMAGE_TAG="${GITBRANCH}"
fi

docker run --runtime nvidia -p 80:80 --network 'host' -d --restart always covid-19-api:${IMAGE_TAG}

#systemctl start spot-instance-interruption-notice-handler
logger "$0: -------------- Starting worker"
systemctl start worker