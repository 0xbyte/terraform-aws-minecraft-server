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
    'body': f"""
      <!DOCTYPE html>
      <html>
      <head>
          <title>Minecraft Server</title>
      </head>
      <body>
          <p>Server is currently {status} with an address of <b>{ip}:{port}</b>.</p>
          <form method="post" action="/start">
              <input type="submit" value="Start Server">
          </form>
          <form method="post" action="/stop">
              <input type="submit" value="Stop Server">
          </form>
      </body>
      </html>""",
    'headers': {
      'Content-Type': 'text/html'
    }
  }
