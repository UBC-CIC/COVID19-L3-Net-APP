#!/bin/bash

urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

urlencode() {
	local LANG=C i c e=''
	for ((i=0;i<${#1};i++)); do
                c=${1:$i:1}
		[[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
                e+="$c"
	done
        echo "$e"
}

update_status () {
  CODE=$1
  MSG=$2
  VER=$3

  jq --arg CODE $CODE --arg VER $VER --arg MSG $MSG '.versions |= map(if .version == $VER then .code = $CODE | .msg = $MSG  else . end)' /mnt/$RANDOM_STRING/${FNAME}.status > /mnt/$RANDOM_STRING/${FNAME}.status.tmp
  rm /mnt/$RANDOM_STRING/${FNAME}.status
  mv /mnt/$RANDOM_STRING/${FNAME}.status.tmp /mnt/$RANDOM_STRING/${FNAME}.status
  aws s3 cp /mnt/$RANDOM_STRING/${FNAME}.status s3://$S3BUCKET/$S3KEY.status
  logger "$0:----> Status changed to $MSG"
}

process_file() {
    logger "$0:----> process_file $1"

    VER=$1
    HOSTPORT="8$(echo $VER | sed 's/[^0-9]*//g')"

    logger "$0:----> Processing $FNAME for $VER"

    # Updating status
    update_status "1" Processing $VER  

    # Unzipping the dcm files
    logger "$0:----> Unzipping DCM files"
    mkdir -p /mnt/$RANDOM_STRING/dcm
    unzip -j -q $LOCALZIPFILE -d /mnt/$RANDOM_STRING/dcm
    # Preping DCM files to be sent to the model (making sure they are under a folder)
    zip -r /mnt/$RANDOM_STRING-dcm.zip /mnt/$RANDOM_STRING/dcm/*

    logger "$0: Start model processing"
    # Submitting file to the model
    echo 
    curl -X POST -F "input_file=@/mnt/$RANDOM_STRING-dcm.zip" http://localhost:$HOSTPORT/predict/?format=png -o /mnt/$RANDOM_STRING/png/$VER.zip
    logger "$0: END model processing"

    # Unzipping the png files
    logger "$0:----> Unzipping PNG files"
    mkdir -p /mnt/$RANDOM_STRING/png/$VER
    unzip -j -q /mnt/$RANDOM_STRING/png.zip -d /mnt/$RANDOM_STRING/png/$VER


    # Preping the data for the JSON File
    STATS=""
    for file in /mnt/$RANDOM_STRING/dcm/*.dcm; do
      echo "\"${CLOUDFRONT}/dcm/$RANDOM_STRING/$(basename $file)\"," >> /mnt/$RANDOM_STRING/dcms-files.txt
    done
    DCMS=$(wc -l /mnt/$RANDOM_STRING/dcms-count.txt)
    echo $DCMS 
    for file in /mnt/$RANDOM_STRING/png/$VER/*.png; do
      echo "\"${CLOUDFRONT}/png/$VER/$RANDOM_STRING/$(basename $file)\"," >> /mnt/$RANDOM_STRING/pngs-$VER-files.txt
    done
    PNGS=$(wc -l /mnt/$RANDOM_STRING/pngs-count.txt)
    echo $PNGS
    for file in /mnt/$RANDOM_STRING/png/$VER/*.json; do
      #Should only be 1 JSON file, so just take the last one.
      STATS="\"${CLOUDFRONT}/png/$VER/$(basename $file)\",\n"
    done
    echo $STATS

    # Copying to the public bucket
    logger "$0:----> Moving DCM and PNG files to S3"
    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/dcm s3://$S3BUCKET/public/dcm/$RANDOM_STRING/
    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/png/$VER s3://$S3BUCKET/public/png/$VER/$RANDOM_STRING/
  
    # html and data.js file
    logger "$0:----> Preping index.html and data.js"
    mkdir -p /mnt/$RANDOM_STRING/html/$VER

    DATAJS=${CLOUDFRONT}/html/$VER/$RANDOM_STRING/data.js

    cp $WORKING_DIR/sapien/$VER/index.html /mnt/$RANDOM_STRING/html/$VER
    sed -i "s|CLOUDFRONT|${CLOUDFRONT}|g" /mnt/$RANDOM_STRING/html/$VER/index.html
    sed -i "s|DATAJS|${DATAJS}|g" /mnt/$RANDOM_STRING/html/$VER/index.html

    cp $WORKING_DIR/sapien/$VER/data.js /mnt/$RANDOM_STRING/html/$VER
    sed -i -e "/%DICOM_FILES%/{r /mnt/$RANDOM_STRING/dcms-files.txt" -e "d}" /mnt/$RANDOM_STRING/html/$VER/data.js
    sed -i -e "/%PNG_FILES%/{r /mnt/$RANDOM_STRING/pngs-$VER-files.txt" -e "d}" /mnt/$RANDOM_STRING/html/$VER/data.js
    sed -i "s|%url_statJson%|${STATS%???}|g" /mnt/$RANDOM_STRING/html/$VER/data.js

    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/html/$VER s3://$S3BUCKET/public/html/$VER/$RANDOM_STRING/

    # Updating status
    update_status "2" Ready $VER 

}

start_model() {
  logger "$0:----> start_model $1"
  TAG=$1
  HOSTPORT="8$(echo $TAG | sed 's/[^0-9]*//g')"
  CONTAINER_STATUS=$(docker ps --format '{{.Image}}')
  if [[ $CONTAINER_STATUS == covid-19* ]]; then
    logger "$0:docker is already up!"
    exit
  fi
  logger "$0:-------------- Starting container model covid-19-api:$TAG --------------"
  CONTAINERID="$(docker run --runtime nvidia -p $HOSTPORT:80 --network 'host' -d --restart always covid-19-api:$TAG)"
  logger "$0:-------------- Done --------------"
  ATTEMPT=0
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
  FNAME_NO_SUFFIX="$(basename $S3KEY .status)"
  FEXT=$(echo $S3KEY | rev | cut -f1 -d"." | rev)

  if [ "$FEXT" == "zip" ]; then

    logger "$0: Found work. Details: FNAME=$FNAME, FNAME_NO_SUFFIX=$FNAME_NO_SUFFIX, FEXT=$FEXT, S3KEY_NO_SUFFIX=$S3KEY_NO_SUFFIX"

    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in

    # Format 2020-07-23 14:01:19 to 202007231401
    # FILE_DATE=$(aws s3 ls s3://$S3BUCKET/$S3KEY | grep -v status | awk -F'[^0-9]*' '{print $1$2$3$4$5}')
    RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-10} | head -n 1)

    mkdir -p /mnt/$RANDOM_STRING

    aws s3 cp s3://$S3BUCKET/$S3KEY.status /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX.status
    aws s3 cp s3://$S3BUCKET/$S3KEY_NO_SUFFIX.zip /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip

    LOCALZIPFILE="/mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX.zip"
    LOCALSTATUSFILE="/mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX.status"   
      
    for VERSION in $(cat $LOCALSTATUSFILE | jq -r '.versions[].version')
    do        
        start_model $VERSION
        if [ -f $LOCALZIPFILE ]; then
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

    rm -rf /mnt/$RANDOM_STRING
    
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
