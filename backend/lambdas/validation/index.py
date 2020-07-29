from pydicom import dcmread
import zipfile
import os
import json
import sys
import boto3
import logging
import html
import urllib.parse
import ntpath

queueUrl = os.getenv('queueUrl')

s3_client = boto3.client('s3')
sqs = boto3.client('sqs')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def setStatusMsg(s3bucket, key, msg, code):
    txtMsg = '{ "code": ' + str(code) + ', "msg": "' + msg +  '"}'
    with open("/tmp/status.json", "w") as text_file:
        text_file.write(txtMsg)
    s3_client.upload_file('/tmp/status.json',s3bucket,key)

def sendSqsMessage(body):
    logger.info("Adding msg to the queue: " + queueUrl)
    response = sqs.send_message(
        QueueUrl=queueUrl,
        MessageBody=json.dumps(body)
    )

def ziptest(filename):
    file_count = 0
    try:
        zipfile.is_zipfile(filename)        
    except:
        logger.info("This file is not a Zip file")
        return "Error: This file is not a Zip file"
    zipfile.ZipFile(filename).extractall(path="/tmp/testfolder")
    logger.info("Extracting zip files")
    files = []
    for r, d, f in os.walk("/tmp/testfolder"):
        for file in f:
            files.append(os.path.join(r, file))
    if len(file) == 0:
        return "Error: This file is not a Zip file"
    for f in files:
        try:
            ds = dcmread(f)
            file_count += 1
        except:
            logger.info("This file is not a DCM file: " + f)
            return "Error: Zip does not contain DCM files"

    logger.info("Validated " + str(file_count) + " dcm files")
    return ""


def handler(event, context):

    #logger.info(event)
    zipKey = urllib.parse.unquote(event["Records"][0]["s3"]["object"]["key"])
    bucket = urllib.parse.unquote(event["Records"][0]["s3"]["bucket"]["name"])

    print(zipKey)

    if len(zipKey) < 2:
        logger.error("something went wrong")
        return False

    zipFilePath = '/tmp/' + ntpath.basename(zipKey)

    s3_client.download_file(bucket, zipKey, zipFilePath)

    rst = ziptest(zipFilePath)

    if (rst[:5].lower()) == "error":
        setStatusMsg(bucket, zipKey + '.status', rst, 3)
        return False
    else:
        sendSqsMessage(event)
        setStatusMsg(bucket, zipKey + '.status', 'Sent to the queue', 0)
        return True