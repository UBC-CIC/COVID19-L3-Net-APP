#!/bin/bash

function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

function urlencode() {
	local LANG=C i c e=''
	for ((i=0;i<${#1};i++)); do
                c=${1:$i:1}
		[[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
                e+="$c"
	done
        echo "$e"
}

function status_content_update() {
  logger "$0:----> status_content_update"
  local $KEY=$1
  local $VALUE=$2

  jq --arg KEY $KEY --arg VALUE $VALUE '.[$KEY] = $VALUE' \
    /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status > \
    "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status.tmp"

  save_status_file "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status.tmp"

}

function update_status () {
  logger "$0:----> update_status $1"
  local CODE=$1
  local MSG=$2
  local VER=$3

  cp /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status \
    mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status.bak

  jq --arg CODE $CODE --arg VER $VER --arg MSG $MSG \
    '.versions |= map(if .version == $VER then .code = $CODE | .msg = $MSG  else . end)' \
    /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status > \
    "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status.tmp"

  save_status_file "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status.tmp"
}

function save_status_file() {
  local TEMPFILE=$1

  rm "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status"
  mv -f $TEMPFILE "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status"
  aws s3 cp /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status s3://$S3BUCKET/$S3KEY_NO_SUFFIX.status
}

function process_file() {
    logger "$0:----> process_file $1"

    local VER=$1
    local HOSTPORT="8$(echo $VER | sed 's/[^0-9]*//g')"
    local STATS=""
    local DCMS=""
    local PNGS=""
    local DATAJS=""

    logger "$0:----> Processing $FNAME for $VER"

    # Updating status
    update_status "1" Processing $VER  

    # Unzipping the dcm files
    if [ ! -f /mnt/efs/ec2/$RANDOM_STRING/dcms.zip ]; then
      logger "$0:----> Unzipping DCM files"
      mkdir -p /mnt/efs/ec2/$RANDOM_STRING/dcm
      unzip -j -q /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip -d /mnt/efs/ec2/$RANDOM_STRING/dcm
      # Preping DCM files to be sent to the model (making sure they are under a folder)
      cd /mnt/efs/ec2/$RANDOM_STRING
      zip -r /mnt/efs/ec2/$RANDOM_STRING/dcms.zip dcm/*
      cd $WORKING_DIR
    fi

    # Start and processing the model
    start_process_model $VER

    # Unzipping the png files
    logger "$0:----> Unzipping PNG files"
    mkdir -p /mnt/efs/ec2/$RANDOM_STRING/png/$VER
    unzip -j -q /mnt/efs/ec2/$RANDOM_STRING/$VER-pngs.zip -d /mnt/efs/ec2/$RANDOM_STRING/png/$VER

    # Preping the data for the JSON File
    if [ ! -f "/mnt/efs/ec2/$RANDOM_STRING/dcms-count.txt" ]; then
      for file in /mnt/efs/ec2/$RANDOM_STRING/dcm/*.dcm; do
        echo "\"${CLOUDFRONT}/dcm/$RANDOM_STRING/$(basename $file)\"," >> /mnt/efs/ec2/$RANDOM_STRING/dcms-files.txt
      done
    fi
    DCMS=$(wc -l /mnt/efs/ec2/$RANDOM_STRING/dcms-files.txt)
    echo $DCMS 

    for file in /mnt/efs/ec2/$RANDOM_STRING/png/$VER/*.png; do
      echo "\"${CLOUDFRONT}/png/$VER/$RANDOM_STRING/$(basename $file)\"," >> /mnt/efs/ec2/$RANDOM_STRING/pngs-$VER-count.txt
    done
    PNGS=$(wc -l /mnt/efs/ec2/$RANDOM_STRING/pngs-$VER-count.txt)
    echo $PNGS
    for file in /mnt/efs/ec2/$RANDOM_STRING/png/$VER/*.json; do
      #Should only be 1 JSON file, so just take the last one.
      STATS="\"${CLOUDFRONT}/png/$VER/$(basename $file)\",\n"
    done
    echo $STATS

    # Copying to the public bucket
    logger "$0:----> Moving DCM and PNG files to S3"
    aws s3 cp --quiet --recursive /mnt/efs/ec2/$RANDOM_STRING/dcm s3://$S3BUCKET/public/dcm/$RANDOM_STRING/
    aws s3 cp --quiet --recursive /mnt/efs/ec2/$RANDOM_STRING/png/$VER s3://$S3BUCKET/public/png/$VER/$RANDOM_STRING/
  
    # html and data.js file
    logger "$0:----> Preping index.html and data.js"
    mkdir -p /mnt/efs/ec2/$RANDOM_STRING/html/$VER

    DATAJS=${CLOUDFRONT}/html/$VER/$RANDOM_STRING/data.js

    cp $WORKING_DIR/sapien/$VER/index.html /mnt/efs/ec2/$RANDOM_STRING/html/$VER
    sed -i "s|CLOUDFRONT|${CLOUDFRONT}|g" /mnt/efs/ec2/$RANDOM_STRING/html/$VER/index.html
    sed -i "s|DATAJS|${DATAJS}|g" /mnt/efs/ec2/$RANDOM_STRING/html/$VER/index.html

    cp $WORKING_DIR/sapien/$VER/data.js /mnt/efs/ec2/$RANDOM_STRING/html/$VER
    sed -i -e "/%DICOM_FILES%/{r /mnt/efs/ec2/$RANDOM_STRING/dcms-files.txt" -e "d}" /mnt/efs/ec2/$RANDOM_STRING/html/$VER/data.js
    sed -i -e "/%PNG_FILES%/{r /mnt/efs/ec2/$RANDOM_STRING/pngs-$VER-files.txt" -e "d}" /mnt/efs/ec2/$RANDOM_STRING/html/$VER/data.js
    sed -i "s|%url_statJson%|${STATS%???}|g" /mnt/efs/ec2/$RANDOM_STRING/html/$VER/data.js

    aws s3 cp --quiet --recursive /mnt/efs/ec2/$RANDOM_STRING/html/$VER s3://$S3BUCKET/public/html/$VER/$RANDOM_STRING/

    # Updating status
    update_status "2" Ready $VER 

}

function start_process_model() {
  logger "$0:----> start_model $1"
  local TAG=$1
  local HOSTPORT="8$(echo $TAG | sed 's/[^0-9]*//g')"
  local CONTAINER_STATUS=$(docker ps --format '{{.Image}}')
  local CONTAINERID=""
  local ATTEMPT=0
  local RESULT=""

  if [[ $CONTAINER_STATUS == covid-19* ]]; then
    logger "$0:docker is already up!"
    exit
  fi
  logger "$0:-------------- Starting container model covid-19-api:$TAG --------------"
  CONTAINERID="$(docker run --runtime nvidia -p 80:80 --network 'host' -d --restart always covid-19-api:$TAG)"
  logger "$0:-------------- Container started --------------"  
  while [ $ATTEMPT -le 8 ]; do
      ATTEMPT=$(( $ATTEMPT + 1 ))
      logger "$0:Waiting for docker to be up (ATTEMPT: $ATTEMPT)..."
      docker logs $CONTAINERID 2>&1 | grep "ERROR"
      RESULT=$(docker logs $CONTAINERID 2>&1 | grep "Listening at: http://0.0.0.0:80" | wc -l)
      if [[ $RESULT -eq 1 ]]; then
        logger "$0:docker is up!"
        break
      fi
      sleep 5
  done

  logger "$0:-------------- Starting model processing"
  curl -X POST -F "input_file=@/mnt/efs/ec2/$RANDOM_STRING/dcms.zip" http://localhost/predict/?format=png -o /mnt/efs/ec2/$RANDOM_STRING/$TAG-pngs.zip
  logger "$0: Killing Container $CONTAINERID"
  docker kill $CONTAINERID
  logger "$0:-------------- start_process_model finished --------------"
}

# Initializing Variables
GITBRANCH=%BRANCH%
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"
CLOUDFRONT="https://$(aws ssm get-parameter --name "/covid19l3/$GITBRANCH/cloudfrontdomain" --query Parameter.Value --output text)"
SQSVPCE=$(aws ssm get-parameter --name "/covid19l3/$GITBRANCH/sqsvpce" --query Parameter.Value --output text)
SQSURL=$(echo $SQSVPCE | cut -d':' -f2)
SQSNAME=$(aws ssm get-parameter --name "/covid19l3/$GITBRANCH/sqsname" --query Parameter.Value --output text)
SQSQUEUE="https://$SQSURL/$SQSNAME"
WORKING_DIR=/root/covid-19-app/backend/sqs-ec2
AUTOSCALINGGROUP=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=aws:autoscaling:groupName" | jq -r '.Tags[0].Value')

logger "$0:  -------------- INSTANCE_ID: $INSTANCE_ID - CLOUDFRONT: $CLOUDFRONT - SQSQUEUE: $SQSQUEUE"

status_content_update "cloudfrontUrl" $CLOUDFRONT

while :;do 

  # Spot instance interruption notice detection
  if [ ! -z $(curl -Isf http://169.254.169.254/latest/meta-data/spot/instance-action) ]; then
    logger "[$0]: spot instance interruption notice detected"
    break 
  fi

  JSON=$(aws sqs --output=json get-queue-attributes \
    --queue-url $SQSQUEUE \
    --attribute-names ApproximateNumberOfMessages)
  MESSAGES=$(echo "$JSON" | jq -r '.Attributes.ApproximateNumberOfMessages')

  if [ $MESSAGES -eq 0 ]; then
    sleep 60
    logger "$0: No messages to process. sleeping for 60 seconds."
    continue
  fi

  JSON=$(aws sqs --output=json receive-message --queue-url $SQSQUEUE)
  RECEIPT=$(echo "$JSON" | jq -r '.Messages[] | .ReceiptHandle')
  BODY=$(echo "$JSON" | jq -r '.Messages[] | .Body')

  if [ -z "$RECEIPT" ]; then
    logger "$0: Empty receipt. Something went wrong."
    continue

  fi

  logger "$0: Found $MESSAGES messages in $SQSQUEUE"

  S3BUCKET=$(echo "$BODY" | jq -r '.Records[0] | .s3.bucket.name')
  INPUT=$(echo "$BODY" | jq -r '.Records[0] | .s3.object.key')
  S3KEY=$(urldecode $INPUT | tr '[:upper:]' '[:lower:]')

  logger "$0: S3KEY=$S3KEY"

  S3KEY_NO_SUFFIX=$(echo $S3KEY | rev | cut -f2 -d"." | rev)
  FNAME=$(basename $S3KEY)
  FNAME_NO_SUFFIX="$(basename $S3KEY .zip)"
  FEXT=$(echo $S3KEY | rev | cut -f1 -d"." | rev)

  if [ "$FEXT" == "zip" ]; then

    #FNAME=patient-a.zip, FNAME_NO_SUFFIX=patient-a.zip, FEXT=zip, S3KEY_NO_SUFFIX=private/us-west-2:5b1169cf-10f3-4b96-9374-64b50110ec13/patient-a
    logger "$0: Found work. Details: FNAME=$FNAME, FNAME_NO_SUFFIX=$FNAME_NO_SUFFIX, FEXT=$FEXT, S3KEY_NO_SUFFIX=$S3KEY_NO_SUFFIX"

    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in

    # Format 2020-07-23 14:01:19 to 202007231401
    # FILE_DATE=$(aws s3 ls s3://$S3BUCKET/$S3KEY | grep -v status | awk -F'[^0-9]*' '{print $1$2$3$4$5}')
    RANDOM_STRING=$(openssl rand -base64 8 | tr -dc 'a-zA-Z0-9')

    status_content_update "uid" $RANDOM_STRING

    logger "$0: RANDOM_STRING: $RANDOM_STRING"

    mkdir -p /mnt/efs/ec2/$RANDOM_STRING

    aws s3 cp --quiet s3://$S3BUCKET/$S3KEY_NO_SUFFIX.status "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status"
    aws s3 cp --quiet s3://$S3BUCKET/$S3KEY_NO_SUFFIX.zip "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip"
 
    logger "$0: LOCALZIPFILE: /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip" 
    logger "$0: LOCALSTATUSFILE: /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status" 
      
    for VERSION in $(cat /mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.status| jq -r '.versions[].version')
    do                
        if [ ! -f "/mnt/efs/ec2/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip" ]; then
          update_status "3" "zip file not found" $VERSION
          exit
        fi 

        if [ -z "$(aws s3 ls $S3BUCKET/public/sapien/$VERSION/sapiencovid_demo.js)" ]; then
          logger "$0: Copying sapien/$VERSION plugin files to S3"
          aws s3 cp --quiet --recursive $WORKING_DIR/sapien/$VERSION/ s3://$S3BUCKET/public/sapien/$VERSION/
        fi
        process_file $VERSION
        # if [ $STATUS_CODE -eq 0 ]; then
        #   process_file      
        # else
        #   logger "$0: ${FNAME} was probably processed by another worker"
        # fi

    done

    rm -rf /mnt/efs/ec2/$RANDOM_STRING
    
    logger "$0: Running: aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT"
    aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT
    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in
    sleep 5
    
  else

    logger "$0: Skipping message - file not of type zip. Deleting message from queue"
    aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT

  fi

done
