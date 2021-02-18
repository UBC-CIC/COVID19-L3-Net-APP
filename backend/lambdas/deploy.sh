#!/bin/bash
if [[ ! -n "$1" ]]; then
    echo "please, provide the github branch name."
    exit 1
fi

GITBRANCH=$1

cd ../layers
./createLayer.sh

cd ../lambdas

BUCKET=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/s3Bucket" --query Parameter.Value --output text)
echo "Bucket: ${BUCKET}"

sam package --s3-bucket $BUCKET --output-template-file out.yaml
sam deploy --template-file out.yaml --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND --stack-name covid-19-app-lambda --parameter-overrides ParameterKey=gitHubBranch,ParameterValue=$GITBRANCH

LAMBDAARN=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/lambdaArn" --query Parameter.Value --output text)
echo "Lambda: ${LAMBDAARN}"

cp notification.json notification.s3 
sed "s|%LambdaArn%|$LAMBDAARN|g" notification.json > notification.s3

echo "Configuring s3Event"
aws s3api put-bucket-notification-configuration --bucket ${BUCKET} --notification-configuration file://notification.s3
rm notification.s3
rm ../layers/*.zip
rm out.yaml