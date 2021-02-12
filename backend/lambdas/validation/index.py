from pydicom import dcmread
import zipfile
import os
import json
import sys
import boto3
import logging
import html
import urllib.parse
import random
import string
import shutil

queueUrl = os.getenv('queueUrl')

s3_client = boto3.client('s3')
sqs = boto3.client('sqs')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def setStatusMsg(statusFile, s3bucket, key, msg, code):
    logger.info("---- setStatusMsg: " + s3bucket + " - " + key + " - " +  statusFile)
    s3_client.download_file(s3bucket, key, statusFile)

    with open(statusFile, 'r') as f:
        data = json.load(f)
        data['code'] = str(code)
        data['msg'] = msg

    os.remove(statusFile)
    with open(statusFile, 'w') as f:
        json.dump(data, f, indent=4)
    
    s3_client.upload_file(statusFile,s3bucket,key)

def sendSqsMessage(body):
    logger.info("---- sendSqsMessage")
    logger.info("Adding msg to the queue: " + queueUrl)
    response = sqs.send_message(
        QueueUrl=queueUrl,
        MessageBody=json.dumps(body)
    )

def ziptest(filename):
    logger.info("---- ziptest " + filename)
    errMsg = ""
    file_count = 0
    letters = string.ascii_lowercase
    temp_path = "/mnt/tmp/" + ( ''.join(random.choice(letters) for i in range(8)) )
    try:
        zipfile.is_zipfile(filename)        
    except:
        logger.info("This file is not a Zip file")
        errMsg = "Error: This file is not a Zip file"

    if len(errMsg) == 0: 
        zipfile.ZipFile(filename).extractall(path=temp_path)
        logger.info("Extracting zip files at " + temp_path)
        files = []
        for r, d, f in os.walk(temp_path):
            for file in f:
                files.append(os.path.join(r, file))
        if len(file) == 0:
            errMsg = "Error: This file is not a Zip file"
        for f in files:
            try:
                ds = dcmread(f)
                file_count += 1
            except:
                logger.info("This file is not a DCM file: " + f)
                errMsg = "Error: This file is not a DCM file: " + f
                break

        logger.info("Validated " + str(file_count) + " dcm files")

    shutil.rmtree(temp_path)
    return errMsg


def handler(event, context):    
    try: 
        #logger.info(event)
        s3Key = urllib.parse.unquote(event["Records"][0]["s3"]["object"]["key"])
        bucket = urllib.parse.unquote(event["Records"][0]["s3"]["bucket"]["name"])
    
        print("S3 Key: " + s3Key)
    
        if len(s3Key) < 2:
            logger.error("something went wrong")
            return False
    
        statusKey = s3Key.replace("zip","status")
        zipFile = '/mnt/tmp/' + s3Key.split(":")[1]
        statusFile = zipFile.replace("zip","status")
        print("statusFile: " + statusFile)
        print("zipFile: " + zipFile)
        print("bucket: " + bucket)

        userDir=os.path.join('/mnt/tmp', s3Key.split(":")[1].split("/")[0])
        print("UserDir: " + userDir)
        if (not os.path.isdir(userDir)):
            os.mkdir(userDir)
    
        s3_client.download_file(bucket, s3Key, zipFile)
    
        rst = ziptest(zipFile)
    
        os.remove(zipFile)
        os.remove(statusFile)
        
        if ("error" in rst.lower()):
            setStatusMsg(statusFile, bucket, statusKey, rst, 3)
            return False
        else:
            sendSqsMessage(event)
            setStatusMsg(statusFile, bucket, statusKey, 'Sent to the queue', 0)
            return True
    
    except Exception as e:
        setStatusMsg(statusFile, bucket, statusKey, str(e), 3)
        os.remove(zipFile)
        os.remove(statusFile)
        logger.error(str(e))
        return False