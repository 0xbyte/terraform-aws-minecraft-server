#!/usr/bin/env python3

import boto3
import os

instances = [os.getenv('MINECRAFT_SERVER_INSTANCE_ID')]
region = os.getenv('MINECRAFT_SERVER_REGION')
port = os.getenv('MINECRAFT_SERVER_PORT')

def lambda_handler(event, context):
  ec2 = boto3.client('ec2', region_name = region)
  response = ec2.describe_instances(InstanceIds=instances)
  ip = response['Reservations'][0]['Instances'][0].get('PublicIpAddress')
  status = response['Reservations'][0]['Instances'][0]['State']['Name']
  return {
    'statusCode': 200,
    'body': f'Server is currently {status} with an address of {ip}:{port}.',
    'headers': {
      'Content-Type': 'text/plain'
    }
  }
