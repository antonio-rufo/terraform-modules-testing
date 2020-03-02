module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = module.vpc.vpc_id
  name        = "EC2-SG"
  description = "security group for ec2 instances"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http ports"
      cidr_blocks = "10.0.0.0/16"
    },
    # {
    #   from_port   = 22
    #   to_port     = 22
    #   protocol    = "tcp"
    #   description = "SSH ports"
    #   cidr_blocks = "10.0.0.0/16"
    # },
  ]
  tags = {
    Name = "EC2-SG"
  }
}

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = module.vpc.vpc_id
  name        = "RDS-SG"
  description = "security group for RDS DB"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "RDS ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "RDS-SG"
  }
}

module "elb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = module.vpc.vpc_id
  name        = "ELB-SG"
  description = "security group for load balancer"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "ELB-SG"
  }
}

# module "db" {
#   source  = "terraform-aws-modules/rds/aws"
#   version = "~> 2.0"
#
#   identifier = "wordpress"
#
#   engine            = "mysql"
#   engine_version    = "8.0.16"
#   instance_class    = "db.t2.micro"
#   allocated_storage = 20
#
#   name     = "wordpress"
#   username = "test"
#   password = "test123$%"
#   port     = "3306"
#
#   skip_final_snapshot    = "true"
#   vpc_security_group_ids = ["${module.rds_sg.this_security_group_id}"]
#
#   tags = {
#     Owner       = "user"
#     Environment = "dev"
#   }
#
#   # DB subnet group
#   subnet_ids = module.vpc.private_subnets
#
#   # DB parameter group
#   family = "mysql8.0"
#
#   # DB option group
#   major_engine_version = "8.0"
#
#   maintenance_window = "Mon:00:00-Mon:03:00"
#   backup_window      = "03:00-06:00"
#
# }

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "elb-example"

  subnets         = module.vpc.public_subnets
  security_groups = ["${module.elb_sg.this_security_group_id}"]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/healthy.html"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "service"

  # Launch configuration
  lc_name = "example-lc"

  image_id        = "ami-0f767afb799f45102"
  instance_type   = "t2.micro"
  security_groups = ["${module.ec2_sg.this_security_group_id}"]

  user_data = file(var.ASG_USER_DATA_WPSTP)

  key_name = aws_key_pair.mykeypair.key_name

  # ebs_block_device = [
  #   {
  #     device_name           = "/dev/xvdz"
  #     volume_type           = "gp2"
  #     volume_size           = "50"
  #     delete_on_termination = true
  #   },
  # ]
  #
  # root_block_device = [
  #   {
  #     volume_size = "50"
  #     volume_type = "gp2"
  #   },
  # ]

  # Auto scaling group
  asg_name                  = "example-asg"
  vpc_zone_identifier       = module.vpc.public_subnets
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  health_check_grace_period = 300
  health_check_type         = "EC2"
  # load_balancers            = ["${module.alb.this_lb_id}"]
  force_delete = true

  # target_group_arns = ["${module.alb.this_lb_id}"]

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
  lifecycle {
    ignore_changes = [public_key]
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = ["${module.elb_sg.this_security_group_id}"]

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name_prefix      = "test"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #     target_group_index = 0
  #   }
  # ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}

### ADDED ON STUFF

module "redirect_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = module.vpc.vpc_id
  name        = "Redirect-SG"
  description = "security group for ec2 instances for redirection"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS Only"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http ports"
      cidr_blocks = "10.0.0.0/16"
    },
  ]
  tags = {
    Name = "Redirect-SG"
  }
}

module "ec2_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "my-cluster"
  instance_count = 1

  ami                    = "ami-0f767afb799f45102"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${module.redirect_sg.this_security_group_id}"]
  subnet_ids             = module.vpc.public_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "this" {
  vpc      = true
  instance = module.ec2_cluster.id[0]
}
