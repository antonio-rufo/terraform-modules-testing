Terraform code that creates:
- a custom VPC in ap-southeast-2 region with
  - 3 public subnets
  - 3 private subnets
  - Internet Gateway
  - NAT Gateway
  - Routing Tables for the Private Subnets
  - Routing Table for the Public Subnet
  - Elastic IP addresses

- Security Groups
  - EC2 security group
  - RDS security group
  - ELB security group

- ELB
  - Associated with the ELB security group
  - Public listening Load Balancer on port 80
  - Will forward traffic to targets in Autoscaling Group

- AutoScaling Group (ASG)
  - Automatically will create EC2 instances basing on Launch configuration
  - Flexible using scripts folder
  - Create EC2 instance with key (pre-requisite)
  - Associated with the EC2 security group

- RDS Database
  - Associated with the RDS security group
  - Private Subnets

External resources modules used:
- VPC
- SG
- ASG
- ELB
- RDS

Steps:

- Create new AWS account
- Create new IAM user with Programmatic Access
- Using credentials, create the private.auto.tfvars
- Create your keypair in folder. Run: ssh-keygen -f mykey
- Run Terraform (init, plan, and apply)
