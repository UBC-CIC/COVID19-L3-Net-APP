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
    jSONSTR=($(jq -r . /mnt/$RANDOM_STRING/${FNAME}.status))
    jq '.code = "$CODE"' <<<"$jSONSTR"
    echo "{ \"code\": $CODE, \"msg\": \"$MSG\", \"cloudfrontUrl\": \"$CLOUDFRONT\" }" > /mnt/$RANDOM_STRING/${FNAME}.status    
    aws s3 cp --quiet /mnt/$RANDOM_STRING/${FNAME}.status s3://$S3BUCKET/$S3KEY.status
    logger "$0:----> Status changed to $MSG"
}

process_file () {
    
    logger "$0:----> Processing $FNAME"

    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in

    # Updating status
    update_status "1" Processing

    # Copying the ZIP CT-Scan file
    aws s3 cp s3://$S3BUCKET/$S3KEY /mnt/$RANDOM_STRING/$FNAME    

    # Preping DCM files to be sent to the model (making sure they are under a folder)
    logger "$0: Preping DCM files"
    unzip -j /mnt/$RANDOM_STRING/$FNAME -d /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-dcm
    zip -r /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-dcm.zip /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-dcm/*

    logger "$0: Start model processing"
    # Submitting file to the model
    echo 
    curl -X POST -F "input_file=@/mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-dcm.zip" http://localhost/predict/?format=png -o /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-png.zip
    logger "$0: END model processing"

    # Unzipping the png files
    logger "$0:----> Unzipping PNG files"
    mkdir -p /mnt/$RANDOM_STRING/png/$FNAME_NO_SUFFIX    
    unzip -j -q /mnt/$RANDOM_STRING/$FNAME_NO_SUFFIX-png.zip -d /mnt/$RANDOM_STRING/png/$FNAME_NO_SUFFIX
    # Unzipping the dcm files
    logger "$0:----> Unzipping DCM files"
    mkdir -p /mnt/$RANDOM_STRING/dcm/$FNAME_NO_SUFFIX
    unzip -j -q /mnt/$RANDOM_STRING/$FNAME -d /mnt/$RANDOM_STRING/dcm/$FNAME_NO_SUFFIX

    # Preping the data for the JSON File
    STATS=""
    for file in /mnt/$RANDOM_STRING/dcm/$FNAME_NO_SUFFIX/*.dcm; do
      echo "\"${CLOUDFRONT}/dcm/$FNAME_NO_SUFFIX-$RANDOM_STRING/$(basename $file)\"," >> /mnt/$RANDOM_STRING/dcms-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt
    done
    DCMS=$(wc -l /mnt/$RANDOM_STRING/dcms-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt)
    echo $DCMS 
    for file in /mnt/$RANDOM_STRING/png/$FNAME_NO_SUFFIX/*.png; do
      echo "\"${CLOUDFRONT}/png/$FNAME_NO_SUFFIX-$RANDOM_STRING/$(basename $file)\"," >> /mnt/$RANDOM_STRING/pngs-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt
    done
    PNGS=$(wc -l /mnt/$RANDOM_STRING/pngs-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt)
    echo $PNGS
    for file in /mnt/$RANDOM_STRING/png/$FNAME_NO_SUFFIX/*.json; do
      #Should only be 1 JSON file, so just take the last one.
      STATS="\"${CLOUDFRONT}/png/$FNAME_NO_SUFFIX-$RANDOM_STRING/$(basename $file)\",\n"
    done
    echo $STATS

    # Copying to the public bucket
    logger "$0:----> Moving DCM and PNG files to S3"
    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/dcm/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/dcm/$FNAME_NO_SUFFIX-$RANDOM_STRING/
    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/png/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/png/$FNAME_NO_SUFFIX-$RANDOM_STRING/
  
    # html and data.js file
    logger "$0:----> Preping index.html and data.js"
    mkdir -p /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX

    DATAJS=${CLOUDFRONT}/html/$FNAME_NO_SUFFIX-$RANDOM_STRING/data.js

    cp $WORKING_DIR/sapien/index.html /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX
    sed -i "s|CLOUDFRONT|${CLOUDFRONT}|g" /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX/index.html
    sed -i "s|DATAJS|${DATAJS}|g" /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX/index.html

    cp $WORKING_DIR/sapien/data.js /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX
    sed -i -e "/%DICOM_FILES%/{r /mnt/$RANDOM_STRING/dcms-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt" -e "d}" /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX/data.js
    sed -i -e "/%PNG_FILES%/{r /mnt/$RANDOM_STRING/pngs-$FNAME_NO_SUFFIX-$RANDOM_STRING.txt" -e "d}" /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX/data.js
    sed -i "s|%url_statJson%|${STATS%???}|g" /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX/data.js

    aws s3 cp --quiet --recursive /mnt/$RANDOM_STRING/html/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/html/$FNAME_NO_SUFFIX-$RANDOM_STRING/

    # Updating status
    update_status "2" Ready    
    logger "$0: Running: aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT"
    aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT
    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in
    sleep 5

}

start_model() {
  TAG=$1
  CONTAINER_STATUS=$(docker ps --format '{{.Image}}')
  if [[ $CONTAINER_STATUS == covid-19* ]]; then
    logger "$0:docker is already up!"
    exit
  fi
  logger "$0:-------------- Starting container model covid-19-api:$TAG --------------"
  CONTAINERID=$(docker run --runtime nvidia -p 80:80 --network 'host' -d --restart always covid-19-api:$TAG)
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
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"
CLOUDFRONT=$(aws ssm get-parameter --name "/covid19l3/cloudfrontdomain" --query Parameter.Value --output text)
CLOUDFRONT="https://$CLOUDFRONT"
SQSQUEUE=$(aws ssm get-parameter --name "/covid19l3/sqsurl" --query Parameter.Value --output text)
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

  logger "$0: Found $MESSAGES messages in $SQSQUEUE. Details: JSON=$JSON, RECEIPT=$RECEIPT, BODY=$BODY"

  S3BUCKET=$(echo "$BODY" | jq -r '.Records[0] | .s3.bucket.name')
  INPUT=$(echo "$BODY" | jq -r '.Records[0] | .s3.object.key')
  S3KEY=$(urldecode $INPUT | tr '[:upper:]' '[:lower:]')

  S3KEY_NO_SUFFIX=$(echo $S3KEY | rev | cut -f2 -d"." | rev)
  FNAME=$(basename $S3KEY)
  FNAME_NO_SUFFIX="$(basename $S3KEY .zip)"
  FEXT=$(echo $S3KEY | rev | cut -f1 -d"." | rev)

  if [ "$FEXT" = "status" ]; then

    logger "$0: Found work. Details: S3KEY=$S3KEY, FNAME=$FNAME, FNAME_NO_SUFFIX=$FNAME_NO_SUFFIX, FEXT=$FEXT, S3KEY_NO_SUFFIX=$S3KEY_NO_SUFFIX"

    # Format 2020-07-23 14:01:19 to 202007231401
    FILE_DATE=$(aws s3 ls s3://$S3BUCKET/$S3KEY | grep -v status | awk -F'[^0-9]*' '{print $1$2$3$4$5}')
    RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-10} | head -n 1)

    aws s3 cp s3://$S3BUCKET/$S3KEY.status /mnt/$RANDOM_STRING/${FNAME}.status
    
    VERSIONS=$(cat /mnt/$RANDOM_STRING/${FNAME}.status | jq -r '.versions' | jq length

    # for i in $(seq 1 $END); do echo $i; done

    # VERTOPROCESS=$(cat /mnt/$RANDOM_STRING/${FNAME}.status | jq -r '.versions[1].version'

    TAG=$(cat /mnt/$RANDOM_STRING/${FNAME}.status | jq -r '.version')
    start_model $TAG

    if [ -z "$(aws s3 ls $S3BUCKET/public/sapien/sapiencovid_demo.js)" ]; then
      logger "$0: Copying sapien plugin files to S3"
      aws s3 cp --quiet --recursive $WORKING_DIR/sapien/ s3://$S3BUCKET/public/sapien/
    fi

    if [ -f "/mnt/$RANDOM_STRING/${FNAME}.status" ]; then
      STATUS_CODE=$(cat /mnt/$RANDOM_STRING/${FNAME}.status | jq -r '.code')
      logger "$0: ${FNAME}.status = $STATUS_CODE"
    else 
      update_status "3" "Status file not found"
    fi

    if [ $STATUS_CODE -eq 0 ]; then
      process_file      
    else
      logger "$0: ${FNAME} was probably processed by another worker"
    fi
    
  else

    logger "$0: Skipping message - file not of type zip. Deleting message from queue"
    aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT

  fi

done
