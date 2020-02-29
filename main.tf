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
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = "0.0.0.0/0"
    },
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

module "ec2_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "my-cluster"
  instance_count = 2

  ami                    = "ami-0f767afb799f45102"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${module.ec2_sg.this_security_group_id}"]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "wordpress"

  engine            = "mysql"
  engine_version    = "8.0.16"
  instance_class    = "db.t2.micro"
  allocated_storage = 20

  name     = "wordpress"
  username = "test"
  password = "test123$%"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = ["${module.rds_sg.this_security_group_id}"]

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = module.vpc.private_subnets

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

}
