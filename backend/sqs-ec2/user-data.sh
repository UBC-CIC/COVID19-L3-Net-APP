#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
WORKING_DIR=/root/COVID19-L3-Net-APP/backend/sqs-ec2

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"
SQSQUEUE=$1
CLOUDWATCHLOGSGROUP=$2
CLOUDFRONT=$3

logger "$0: -------------- Initializing user-data.sh Account: ${ACCOUNT} - Region: ${REGION} - Queue: ${SQSQUEUE} - Logs: ${CLOUDWATCHLOGSGROUP} - CDN: ${CLOUDFRONT}"

yum -y --security update

yum -y update aws-cli

yum -y install awslogs jq imagemagick

# This fixes awslogsd.service error (ImportError: cannot import name _normalize_host)
pip install --user sphinx

aws configure set default.region $REGION

cp -av $WORKING_DIR/awslogs.conf /etc/awslogs/
cp -av $WORKING_DIR/spot-instance-interruption-notice-handler.service /etc/systemd/system/spot-instance-interruption-notice-handler.service
cp -av $WORKING_DIR/worker.service /etc/systemd/system/worker.service
cp -av $WORKING_DIR/spot-instance-interruption-notice-handler.sh /usr/local/bin/
cp -av $WORKING_DIR/worker.sh /usr/local/bin

chmod +x /usr/local/bin/spot-instance-interruption-notice-handler.sh
chmod +x /usr/local/bin/worker.sh

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf
sed -i "s|%CLOUDWATCHLOGSGROUP%|$CLOUDWATCHLOGSGROUP|g" /etc/awslogs/awslogs.conf
sed -i "s|%REGION%|$REGION|g" /usr/local/bin/worker.sh
sed -i "s|%SQSQUEUE%|$SQSQUEUE|g" /usr/local/bin/worker.sh
sed -i "s|%WORKING_DIR%|$WORKING_DIR|g" /usr/local/bin/worker.sh
sed -i "s|%CLOUDFRONT%|$CLOUDFRONT|g" /usr/local/bin/worker.sh
#sed -i "s|%PUBLICBUCKET%|$PUBLICBUCKET|g" /usr/local/bin/worker.sh

systemctl start awslogsd

REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY
docker pull ${REGISTRY}/covid-19-api:dev
docker tag ${REGISTRY}/covid-19-api:dev covid-19-api:dev
docker run --runtime nvidia -p 80:80 --network 'host' -d --restart always covid-19-api:dev

#systemctl start spot-instance-interruption-notice-handler
logger "$0: -------------- Starting worker"
systemctl start worker