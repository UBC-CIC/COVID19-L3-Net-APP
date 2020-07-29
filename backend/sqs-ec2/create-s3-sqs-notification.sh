#!/bin/bash

BUCKET=$1
LAMBDANAME=$2
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REGION="$(aws s3api get-bucket-location --bucket ${BUCKET} --output text)"

LambdaFunctionArn="arn:aws:lambda:${REGION}:${ACCOUNT}:function:${LAMBDANAME}"

sed "s/LambdaFunctionArn/$LambdaFunctionArn/" notification.json > notification.sqs
aws s3api put-bucket-notification-configuration --bucket ${BUCKET} --notification-configuration file://notification.sqs
rm notification.sqs