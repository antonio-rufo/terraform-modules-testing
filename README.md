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

- EC2 instance
  - Associated with the EC2 security group
  - Public Subnets

- RDS Database
  - Associated with the RDS security group
  - Private Subnets

External resources modules used:
- VPC
- SG
- EC2
- RDS
