# ── CloudWatch Log Group pour Docker ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "nextcloud_docker" {
  name              = "/nextcloud/docker"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-${var.environment}-docker-logs"
    Owner = var.owner_tag
  }
}

# ── Application Load Balancer ─────────────────────────────────────────────────
# ALB public intentionnel : point d'entrée Nextcloud pour les utilisateurs
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "nextcloud" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.public_subnet_ids

  # tfsec: aws-elb-drop-invalid-headers
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.alb_logs_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name  = "${var.project_name}-${var.environment}-alb"
    Owner = var.owner_tag
  }
}

# ── Target Group ──────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "nextcloud" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/status.php"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name  = "${var.project_name}-${var.environment}-tg"
    Owner = var.owner_tag
  }
}

# ── Listener HTTPS ────────────────────────────────────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud.arn
  }
}

# Redirect HTTP → HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Ingress HTTP sur ALB SG pour le redirect
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = var.sg_alb_id
  description       = "Allow HTTP from internet (for redirect)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── Launch Template ───────────────────────────────────────────────────────────
resource "aws_launch_template" "nextcloud" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  description   = "Launch template for Nextcloud instances"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # En VPC non default, utiliser les IDs de security groups
  vpc_security_group_ids = [var.sg_ec2_id]

  # IMDSv2 obligatoire
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # IAM Instance Profile
  dynamic "iam_instance_profile" {
    for_each = var.instance_profile_name != null ? [var.instance_profile_name] : []
    content {
      name = iam_instance_profile.value
    }
  }

  # EBS root chiffré KMS
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      #kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    aws_region       = var.aws_region
    db_secret_arn    = var.db_secret_arn
    admin_secret_arn = var.admin_secret_arn
    db_host          = var.db_host
    db_name          = var.db_name
    s3_bucket        = var.nextcloud_bucket_name
    log_group        = aws_cloudwatch_log_group.nextcloud_docker.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-instance"
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner_tag
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-volume"
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner_tag
    }
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = {
      Name        = "${var.project_name}-${var.environment}-eni"
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner_tag
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-lt"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner_tag
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────
resource "aws_autoscaling_group" "nextcloud" {
  count               = var.create_asg ? 1 : 0
  name                = "${var.project_name}-${var.environment}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns         = [aws_lb_target_group.nextcloud.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.nextcloud.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = var.owner_tag
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Instance EC2 directe (fallback compte formation) ──────────────────────────
# ENI créé séparément pour satisfaire formation-require-owner-tag sur network-interface
resource "aws_network_interface" "nextcloud" {
  count           = var.create_asg ? 0 : 1
  subnet_id       = var.private_subnet_ids[0]
  security_groups = [var.sg_ec2_id]

  tags = {
    Name  = "${var.project_name}-${var.environment}-eni"
    Owner = var.owner_tag
  }
}

resource "aws_instance" "nextcloud" {
  count                = var.create_asg ? 0 : 1
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_profile_name

  network_interface {
    network_interface_id = aws_network_interface.nextcloud[0].id
    device_index         = 0
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    aws_region       = var.aws_region
    db_secret_arn    = var.db_secret_arn
    admin_secret_arn = var.admin_secret_arn
    db_host          = var.db_host
    db_name          = var.db_name
    s3_bucket        = var.nextcloud_bucket_name
    log_group        = aws_cloudwatch_log_group.nextcloud_docker.name
  }))

  tags = {
    Name  = "${var.project_name}-${var.environment}-instance"
    Owner = var.owner_tag
  }
}

resource "aws_lb_target_group_attachment" "nextcloud" {
  count            = var.create_asg ? 0 : 1
  target_group_arn = aws_lb_target_group.nextcloud.arn
  target_id        = aws_instance.nextcloud[0].id
  port             = 8080
}