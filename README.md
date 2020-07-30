# terraform-aws-minecraft-server

Terraform module for deploying a Minecraft server into AWS alongside Lambda functions for powering on and off the server by visiting specific URLs.

## Deployment

Deploy all of the infrastructure by applying the Terraform configuration:
```bash
terraform apply
```

Stop the server:
```bash
aws ec2 stop-instances --instance-ids $(terraform output -json | jq -r '.minecraft_server_instance_id.value')
``` 

Upload the server files to the S3 bucket:
```bash
aws s3 sync ./mc_server_files s3://$(terraform output -json | jq -r '.server_files_bucket_name.value')
``` 

Start the server:
```bash
aws ec2 start-instances --instance-ids $(terraform output -json | jq -r '.minecraft_server_instance_id.value')
``` 

## Managing the Server
This module also deploys three Lambda functions that can be invoked to start, stop and view the status (including current IP address) of the Minecraft server. The `server_status_url` output displays the URL of the status page where the server can be managed.

The Minecraft server will autosave the world every 5 minutes, so it's best to wait 5 minutes after disconnecting before switching off the instance. 

## Downloading Files
Use the following command to sync the remote bucket's Minecraft server files back to the local directory. 
```bash
aws s3 sync s3://$(terraform output -json | jq -r '.server_files_bucket_name.value') ./mc_server_files/
```

### Clearing Files
The S3 bucket has versioning enabled so in order to clear all of the files from the bucket you would need to manually delete all of the files as well as the delete markers.

### Potential Improvements
- Disable S3 bucket versioning and instead periodically on the server zip up files and save them zip to the server (deleting older backups).
- Add CloudWatch alarm to automatically switch off instance after a period of low CPU activity.