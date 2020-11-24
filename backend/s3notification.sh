#!/bin/bash

LAMBDAARN=$(aws cloudformation describe-stacks --stack-name $2 --query "Stacks[0].Outputs[?OutputKey=='ValidationArn'].OutputValue" --output text)
BUCKET=$(aws cloudformation describe-stacks --stack-name $1 --query "Stacks[0].Parameters[?ParameterKey=='s3Bucket'].ParameterValue" --output text)

echo "Bucket: ${BUCKET}"
echo "Lambda: ${LAMBDAARN}"

cp notification.json notification.s3 
sed "s|%LambdaArn%|$LAMBDAARN|g" notification.s3
aws s3api put-bucket-notification-configuration --bucket ${BUCKET} --notification-configuration file://notification.s3