#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REGION="$(curl -s http://169.254.169.254/latest/meta-data/local-hostname | cut -d . -f 2)"

# ${sqsUrl} ${cloudfrontDomain} ${gitBranch}

SQSQUEUE=$1
CLOUDFRONT=$2
GITBRANCH=$3

WORKING_DIR=/root/covid-19-app-${GITBRANCH}/backend/sqs-ec2

logger "$0: -------------- Initializing user-data.sh Account: ${ACCOUNT} - Region: ${REGION} - Queue: ${SQSQUEUE} - CDN: ${CLOUDFRONT} - Branch: ${GITBRANCH}"

aws configure set default.region $REGION

cp -av $WORKING_DIR/spot-instance-interruption-notice-handler.service /etc/systemd/system/spot-instance-interruption-notice-handler.service
cp -av $WORKING_DIR/worker.service /etc/systemd/system/worker.service
cp -av $WORKING_DIR/spot-instance-interruption-notice-handler.sh /usr/local/bin/
cp -av $WORKING_DIR/worker.sh /usr/local/bin
chmod +x /usr/local/bin/spot-instance-interruption-notice-handler.sh
chmod +x /usr/local/bin/worker.sh 

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
logger "$0: -------------- Starting worker --------------"
systemctl start worker