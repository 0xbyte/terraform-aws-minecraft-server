#!/usr/bin/env python3

import boto3
import os

instances = [os.getenv('MINECRAFT_SERVER_INSTANCE_ID')]
region = os.getenv('AWS_REGION')

def lambda_handler(event, context):
  ec2 = boto3.client('ec2', region_name = region)
  ec2.stop_instances(InstanceIds=instances)
  return {
    'statusCode': 200,
    'body': 'Server stopped.'
  }
