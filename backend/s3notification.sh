#!/bin/bash

GITBRANCH=$1

LAMBDAARN=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/lambdaArn" --query Parameter.Value --output text)
BUCKET=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/s3Bucket" --query Parameter.Value --output text)

echo "Bucket: ${BUCKET}"
echo "Lambda: ${LAMBDAARN}"

cp notification.json notification.s3 
sed "s|%LambdaArn%|$LAMBDAARN|g" notification.json > notification.s3

aws s3api put-bucket-notification-configuration --bucket ${BUCKET} --notification-configuration file://notification.s3
rm notification.s3