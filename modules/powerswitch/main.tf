module "powerswitch_label" {
  source = "cloudposse/label/null"
  version = "0.16.0"
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
  version = "3.13.0"
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

resource "aws_lb_target_group" "get_server_status_tg" {
  name = "${module.powerswitch_label.id}-getstatus"
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

module "start_server_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "1.17.0"
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

module "stop_server_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "1.17.0"
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

resource "aws_lb_listener_rule" "get_server_status_endpoint_rule" {
  listener_arn = aws_lb_listener.listener.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.get_server_status_tg.arn
  }
  condition {
    path_pattern {
      values = [
        "/status"]
    }
  }
}

module "get_server_status_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "1.17.0"
  function_name = "${module.powerswitch_label.id}-get-server-status"
  description = "Function for getting the status of the Minecraft server instance"
  handler = "get_server_status.lambda_handler"
  runtime = "python3.8"
  source_path = "${path.module}/bin/get_server_status.py"
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
      "Action": "ec2:DescribeInstances",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "get_server_status_permission" {
  action = "lambda:InvokeFunction"
  function_name = module.get_server_status_function.this_lambda_function_arn
  principal = "elasticloadbalancing.amazonaws.com"
  source_arn = aws_lb_target_group.get_server_status_tg.arn
}

resource "aws_lb_target_group_attachment" "attach_get_server_status_function" {
  target_group_arn = aws_lb_target_group.get_server_status_tg.arn
  target_id        = module.get_server_status_function.this_lambda_function_arn
  depends_on       = [aws_lambda_permission.get_server_status_permission]
}

data "aws_route53_zone" "zone" {
  name = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.zone.id
  name = "${var.hostname}.${var.hosted_zone_name}"
  type = "A"
  alias {
    name = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}
