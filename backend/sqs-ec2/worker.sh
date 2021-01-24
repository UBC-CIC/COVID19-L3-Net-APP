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
    echo "{ \"code\": $CODE, \"msg\": \"$MSG\", \"cloudfrontUrl\": \"$CLOUDFRONT\" }" > /mnt/${FNAME}.status    
    aws s3 cp --quiet /mnt/${FNAME}.status s3://$S3BUCKET/$S3KEY.status
    logger "$0:----> Status changed to $MSG"
}

process_file () {
    
    logger "$0:----> Processing $FNAME"

    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in"
    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --protected-from-scale-in

    # Updating status
    update_status "1" Processing

    # Copying the ZIP CT-Scan file
    aws s3 cp s3://$S3BUCKET/$S3KEY /mnt/$FNAME
    #
    # 2020-07-23 14:01:19
    # 202007231401
    FILE_DATE=$(aws s3 ls s3://$S3BUCKET/$S3KEY | grep -v status | awk -F'[^0-9]*' '{print $1$2$3$4$5}')

    logger "$0: Start model processing"
    # Submitting file to the model
    echo 
    curl -X POST -F "input_file=@/mnt/$FNAME" http://localhost/predict/?format=png -o /mnt/$FNAME_NO_SUFFIX-png.zip
    logger "$0: END model processing"

    # Unzipping the png files
    logger "$0:----> Unzipping PNG files"
    mkdir -p /mnt/png/$FNAME_NO_SUFFIX    
    unzip -j -q /mnt/$FNAME_NO_SUFFIX-png.zip -d /mnt/png/$FNAME_NO_SUFFIX
    # Unzipping the dcm files
    logger "$0:----> Unzipping DCM files"
    mkdir -p /mnt/dcm/$FNAME_NO_SUFFIX
    unzip -j -q /mnt/$FNAME -d /mnt/dcm/$FNAME_NO_SUFFIX

    # Preping the data for the JSON File
    DCMS=""
    PNGS=""
    STATS=""
    for file in /mnt/dcm/$FNAME_NO_SUFFIX/*.dcm; do
      DCMS+="\"${CLOUDFRONT}/dcm/$FNAME_NO_SUFFIX-$FILE_DATE/$(basename $file)\",\n"
    done
    for file in /mnt/png/$FNAME_NO_SUFFIX/*.png; do
      PNGS+="\"${CLOUDFRONT}/png/$FNAME_NO_SUFFIX-$FILE_DATE/$(basename $file)\",\n"
    done
    for file in /mnt/png/$FNAME_NO_SUFFIX/*.json; do
      #Should only be 1 JSON file, so just take the last one.
      STATS="\"${CLOUDFRONT}/png/$FNAME_NO_SUFFIX-$FILE_DATE/$(basename $file)\",\n"
    done

    # Copying to the public bucket
    logger "$0:----> Moving DCM and PNG files to S3"
    aws s3 cp --quiet --recursive /mnt/dcm/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/dcm/$FNAME_NO_SUFFIX-$FILE_DATE/
    aws s3 cp --quiet --recursive /mnt/png/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/png/$FNAME_NO_SUFFIX-$FILE_DATE/
  
    # html and data.js file
    logger "$0:----> Preping index.html and data.js"
    mkdir -p /mnt/html/$FNAME_NO_SUFFIX

    DATAJS=${CLOUDFRONT}/html/$FNAME_NO_SUFFIX-$FILE_DATE/data.js

    cp $WORKING_DIR/sapien/index.html /mnt/html/$FNAME_NO_SUFFIX
    sed -i "s|CLOUDFRONT|${CLOUDFRONT}|g" /mnt/html/$FNAME_NO_SUFFIX/index.html
    sed -i "s|DATAJS|${DATAJS}|g" /mnt/html/$FNAME_NO_SUFFIX/index.html

    cp $WORKING_DIR/sapien/data.js /mnt/html/$FNAME_NO_SUFFIX
    sed -i "s|%DICOM_FILES%|${DCMS%???}|g" /mnt/html/$FNAME_NO_SUFFIX/data.js
    sed -i "s|%PNG_FILES%|${PNGS%???}|g" /mnt/html/$FNAME_NO_SUFFIX/data.js
    sed -i "s|%url_statJson%|${STATS%???}|g" /mnt/html/$FNAME_NO_SUFFIX/data.js

    aws s3 cp --quiet --recursive /mnt/html/$FNAME_NO_SUFFIX s3://$S3BUCKET/public/html/$FNAME_NO_SUFFIX-$FILE_DATE/

    # Updating status
    update_status "2" Ready    

    logger "$0: Running: aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT"

    aws sqs --output=json delete-message --queue-url $SQSQUEUE --receipt-handle $RECEIPT

    logger "$0: Running: aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in"

    aws autoscaling set-instance-protection --instance-ids $INSTANCE_ID --auto-scaling-group-name $AUTOSCALINGGROUP --no-protected-from-scale-in

    sleep 5

}

GITBRANCH="%gitBranchVar%"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"
CLOUDFRONT=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/cloudfrontdomain" --query Parameter.Value --output text)
CLOUDFRONT="https://$CLOUDFRONT"
SQSQUEUE=$(aws ssm get-parameter --name "/covid19l3/${GITBRANCH}/sqsurl" --query Parameter.Value --output text)
WORKING_DIR=/root/covid-19-app-${GITBRANCH}/backend/sqs-ec2
AUTOSCALINGGROUP=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=aws:autoscaling:groupName" | jq -r '.Tags[0].Value')

logger "$0:  -------------- INSTANCE_ID: $INSTANCE_ID - CLOUDFRONT: $CLOUDFRONT - SQSQUEUE: $SQSQUEUE"

logger "$0: -------------- container tag  --------------"
if [[ "${GITBRANCH}" == "master" ]]; then
  IMAGE_TAG="latest"
else
  IMAGE_TAG="${GITBRANCH}"
fi 

logger "$0:-------------- Starting container model covid-19-api:$IMAGE_TAG --------------"
CONTAINERID=$(docker run --runtime nvidia -p 80:80 --network 'host' -d --restart always covid-19-api:$IMAGE_TAG)
logger "$0:-------------- Done --------------"
ATTEMPT=0
while [ $ATTEMPT -le 8 ]; do
    ATTEMPT=$(( $ATTEMPT + 1 ))
    logger "$0:Waiting for server to be up (ATTEMPT: $ATTEMPT)..."
    docker logs $CONTAINERID 2>&1 | grep "ERROR"
    RESULT=$(docker logs $CONTAINERID 2>&1 | grep "Listening at: http://0.0.0.0:80" | wc -l)
    if [[ $RESULT -eq 1 ]]; then
      logger "$0:Model is up!"
      break
    fi
    sleep 5
done


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

  if [ "$FEXT" = "zip" ]; then

    logger "$0: Found work. Details: S3KEY=$S3KEY, FNAME=$FNAME, FNAME_NO_SUFFIX=$FNAME_NO_SUFFIX, FEXT=$FEXT, S3KEY_NO_SUFFIX=$S3KEY_NO_SUFFIX"

    if [ -z "$(aws s3 ls $S3BUCKET/public/sapien/sapiencovid_demo.js)" ]; then
      logger "$0: Copying sapien plugin files to S3"
      aws s3 cp --quiet --recursive $WORKING_DIR/sapien/ s3://$S3BUCKET/public/sapien/
    fi

    aws s3 cp s3://$S3BUCKET/$S3KEY.status /mnt/${FNAME}.status

    if [ -f "/mnt/${FNAME}.status" ]; then
      STATUS_CODE=$(cat /mnt/${FNAME}.status | jq -r '.code')
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
