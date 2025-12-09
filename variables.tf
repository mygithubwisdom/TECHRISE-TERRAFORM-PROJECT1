# VPC Variables
variable "aws_region" {
  description = "eu-west-1"

}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

# Subnet Variables
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  type        = bool
  default     = true
}

# Route Table Variables
variable "public_route_table_name" {
  description = "Name of the public route table"
  type        = string
}

variable "private_route_table_name" {
  description = "Name of the private route table"
  type        = string
}

# Security Group Variables
variable "public_sg_name" {
  description = "Name of the public security group"
  type        = string
}

variable "public_sg_description" {
  description = "Description of the public security group"
  type        = string
  default     = "Allow HTTP, HTTPS, and SSH traffic for public instances"
}

variable "private_sg_name" {
  description = "Name of the private security group"
  type        = string
}

variable "private_sg_description" {
  description = "Description of the private security group"
  type        = string
}

variable "public_sg_ingress_rules" {
  description = "Ingress rules for the public security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow HTTP traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow SSH traffic"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Network ACL Variables
variable "public_nacl_name" {
  description = "Name of the public network ACL"
  type        = string
  default     = "PublicSubnetNACL"
}

variable "private_nacl_name" {
  description = "Name of the private network ACL"
  type        = string
  default     = "PrivateSubnetNACL"
}

# Port Variables
variable "http_port" {
  description = "HTTP port"
  type        = number
}

variable "https_port" {
  description = "HTTPS port"
  type        = number
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
}

variable "db_port" {
  description = "Database port"
  type        = number
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks for SSH access"
  type        = string
}

variable "public_key_name" {
  description = "The name of the key pair to use for the public EC2 instance"
  type        = string
  #default     = "my-public-key" 
}
# Add your variable declarations here
variable "public_instance_ami" {
  description = "The AMI ID for the public instance"
  type        = string
}
variable "instance_type" {
  description = "The type of instance to use for the EC2 instances"
  type        = string
}
# Add your variable declarations here

variable "root_volume_type" {
  description = "The type of volume to use for the root block device"
  type        = string
}
# Add your variable declarations here

variable "root_volume_size" {
  description = "The size of the root volume in GB"
  type        = number
  default     = 8
}
# Add your variable declarations here

variable "public_instance_name" {
  description = "The name tag for the public EC2 instance"
  type        = string
}
# Add your variable declarations here

variable "private_instance_ami" {
  description = "The AMI ID for the private instance"
  type        = string
}
# Add your variable declarations here

variable "private_key_name" {
  description = "The name of the private key pair to use for the private EC2 instance"
  type        = string
}
# Add your variable declarations here

variable "private_instance_name" {
  description = "The name tag for the private instance"
  type        = string
}
# Add your variable declarations here

variable "nat_eip_name" {
  description = "The name tag for the NAT Elastic IP"
  type        = string
  #default     = "NAT-EIP"
}
# Add your variable declarations here

variable "nat_gateway_name" {
  description = "The name of the NAT Gateway"
  type        = string
}

# Monitoring module inputs
variable "monitoring_alarm_email_addresses" {
  description = "Email addresses to subscribe to CloudWatch alarms (empty to skip)."
  type        = list(string)
  default     = []
}

variable "monitoring_alarm_name_prefix" {
  description = "Prefix for monitoring alarm names and log groups."
  type        = string
  default     = "ec2-monitoring"
}

variable "monitoring_create_sns_topic" {
  description = "Create a dedicated SNS topic for monitoring alerts."
  type        = bool
  default     = true
}

variable "monitoring_existing_sns_topic_arn" {
  description = "Use an existing SNS topic ARN instead of creating a new one."
  type        = string
  default     = ""
}

variable "monitoring_cpu_high_threshold" {
  description = "CPU utilization percentage that raises an alarm."
  type        = number
  default     = 80
}

variable "monitoring_network_in_threshold_bytes" {
  description = "Inbound network bytes per period that raises an alarm."
  type        = number
  default     = 104857600 # 100 MB
}