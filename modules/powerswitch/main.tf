module "powerswitch_label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  namespace = "minecraft"
  name = "powerswitch"
  delimiter = "-"

  tags = {
    "Project" = "MinecraftServer",
    "Component" = "Power Switch"
  }
}

module "alb_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  name = "${module.powerswitch_label.id}-alb"
  description = "Allow TCP traffic on 80 from anywehere."
  vpc_id = var.vpc_id
  ingress_cidr_blocks = [
    "0.0.0.0/0"]
  ingress_rules = [
    "http-80-tcp"]

  // TODO could allow egress only to the EC2 service rather than everywhere.
  egress_rules = [
    "all-all"]

  tags = module.powerswitch_label.tags
}

resource "aws_lb" "alb" {
  name = module.powerswitch_label.id
  internal = false
  load_balancer_type = "application"
  security_groups = [
    module.alb_security_group.this_security_group_id]
  subnets = var.subnet_ids
  tags = module.powerswitch_label.tags
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
    }
  }
}

resource "aws_lb_target_group" "start_server_tg" {
  name = "${module.powerswitch_label.id}-start"
  target_type = "lambda"
}

resource "aws_lb_target_group" "stop_server_tg" {
  name = "${module.powerswitch_label.id}-stop"
  target_type = "lambda"
}

resource "aws_lb_listener_rule" "start_server_endpoint_rule" {
  listener_arn = aws_lb_listener.listener.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.start_server_tg.arn
  }
  condition {
    path_pattern {
      values = [
        "/start"]
    }
  }
}

resource "aws_lb_listener_rule" "stop_server_endpoint_rule" {
  listener_arn = aws_lb_listener.listener.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.stop_server_tg.arn
  }
  condition {
    path_pattern {
      values = [
        "/stop"]
    }
  }
}

module "start_server_function" {
  source = "terraform-aws-modules/lambda/aws"
  function_name = "${module.powerswitch_label.id}-start-server"
  description = "Function for starting the Minecraft server instance"
  handler = "start_server.lambda_handler"
  runtime = "python3.8"
  source_path = "${path.module}/bin/start_server.py"
  environment_variables = {
    MINECRAFT_SERVER_INSTANCE_ID = var.server_instance_id
    MINECRAFT_SERVER_REGION = var.region
  }
  tags = module.powerswitch_label.tags
  attach_policy_json = true
  policy_json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:StartInstances",
      "Resource": "${var.server_instance_arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

module "stop_server_function" {
  source = "terraform-aws-modules/lambda/aws"
  function_name = "${module.powerswitch_label.id}-stop-server"
  description = "Function for stopping the Minecraft server instance"
  handler = "stop_server.lambda_handler"
  runtime = "python3.8"
  source_path = "${path.module}/bin/stop_server.py"
  environment_variables = {
    MINECRAFT_SERVER_INSTANCE_ID = var.server_instance_id
    MINECRAFT_SERVER_REGION = var.region
  }
  tags = module.powerswitch_label.tags
  attach_policy_json = true
  policy_json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ec2:StopInstances",
      "Resource": "${var.server_instance_arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "start_server_permission" {
  action = "lambda:InvokeFunction"
  function_name = module.start_server_function.this_lambda_function_arn
  principal = "elasticloadbalancing.amazonaws.com"
  source_arn = aws_lb_target_group.start_server_tg.arn
}

resource "aws_lb_target_group_attachment" "attach_start_server_function" {
  target_group_arn = aws_lb_target_group.start_server_tg.arn
  target_id        = module.start_server_function.this_lambda_function_arn
  depends_on       = [aws_lambda_permission.start_server_permission]
}

resource "aws_lambda_permission" "stop_server_permission" {
  action = "lambda:InvokeFunction"
  function_name = module.stop_server_function.this_lambda_function_arn
  principal = "elasticloadbalancing.amazonaws.com"
  source_arn = aws_lb_target_group.stop_server_tg.arn
}

resource "aws_lb_target_group_attachment" "attach_stop_server_function" {
  target_group_arn = aws_lb_target_group.stop_server_tg.arn
  target_id        = module.stop_server_function.this_lambda_function_arn
  depends_on       = [aws_lambda_permission.stop_server_permission]
}
