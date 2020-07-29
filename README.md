# terraform-aws-minecraft-server

Terraform module for deploying a Minecraft server into AWS alongside Lambda functions for powering on and off the server by visiting specific URLs.

## Downloading Server Files
Use the following command to sync the remote bucket's Minecraft server files to the local directory. 
```bash
aws s3 sync s3://$(terraform output -json | jq -r '.server_files_bucket_name.value') ./mc_server_files/
```

## Potential Improvements
- Find a way to only upload the Minecraft server files if the S3 bucket is empty. This would stop subsequent `apply`s of the configuration re-uploading the local files to the bucket potentially overwriting any changes the server running on the EC2 instance has made to the data.
- Pin the Terraform modules to specific versions.
- Create memorable DNS record that points to the power switch load balancer.
