module "add_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = module.vpc.vpc_id
  name        = "EC2-SG"
  description = "security group for ec2 instances"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "HTTPS"
      description = "HTTPS Only"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "HTTP"
      description = "http ports"
      cidr_blocks = "10.0.0.0/16"
    },
  ]
  tags = {
    Name = "EC2-SG"
  }
}

# module "asg" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#   version = "~> 3.0"
#
#   name = "service"
#
#   # Launch configuration
#   lc_name = "example-lc"
#
#   image_id        = "ami-0f767afb799f45102"
#   instance_type   = "t2.micro"
#   security_groups = ["${module.ec2_sg.this_security_group_id}"]
#
#   user_data = file(var.ASG_USER_DATA_WPSTP)
#
#   key_name = aws_key_pair.mykeypair.key_name
#
#   # Auto scaling group
#   asg_name                  = "example-asg"
#   vpc_zone_identifier       = module.vpc.public_subnets
#   min_size                  = 0
#   max_size                  = 1
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0
#
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   # load_balancers            = ["${module.alb.this_lb_id}"]
#   force_delete = true
#
#   # target_group_arns = ["${module.alb.this_lb_id}"]
#
#   tags = [
#     {
#       key                 = "Environment"
#       value               = "dev"
#       propagate_at_launch = true
#     },
#     {
#       key                 = "Project"
#       value               = "megasecret"
#       propagate_at_launch = true
#     },
#   ]
#
#   tags_as_map = {
#     extra_tag1 = "extra_value1"
#     extra_tag2 = "extra_value2"
#   }
# }
#
# resource "aws_key_pair" "mykeypair" {
#   key_name   = "mykey"
#   public_key = file(var.PATH_TO_PUBLIC_KEY)
#   lifecycle {
#     ignore_changes = [public_key]
#   }
# }
