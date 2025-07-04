# Create a VPC
resource "aws_vpc" "KCVPC" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# Subnets
resource "aws_subnet" "PublicSubnet" {
  vpc_id                  = aws_vpc.KCVPC.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id            = aws_vpc.KCVPC.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zones[1]

  tags = {
    Name = var.private_subnet_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = "${var.vpc_name}-IGW"
  }
}

# Public Route Table
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.KCVPC.id

  # Route for IPv4 traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = var.public_route_table_name
  }
}

# Associate the Public Route Table with the Public Subnet
resource "aws_route_table_association" "PublicSubnetAssociation" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

# Private Route Table
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.KCVPC.id

  # No direct route to the internet
  tags = {
    Name = var.private_route_table_name
  }
}

# Associate the Private Route Table with the Private Subnet
resource "aws_route_table_association" "PrivateSubnetAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

# Security Group for Public Instances (e.g., Web Servers)
resource "aws_security_group" "public_sg" {
  name        = var.public_sg_name
  description = var.public_sg_description
  vpc_id      = aws_vpc.KCVPC.id

  dynamic "ingress" {
    for_each = var.public_sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.public_sg_name
  }
}

# Security Group for Private Instances (e.g., Database Servers)
resource "aws_security_group" "private_sg" {
  name        = var.private_sg_name
  description = var.private_sg_description
  vpc_id      = aws_vpc.KCVPC.id

  ingress {
    description = "Allow PostgreSQL traffic from public subnet"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.private_sg_name
  }
}

# Create a NACL for the Public Subnet
resource "aws_network_acl" "PublicSubnetNACL" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = var.public_nacl_name
  }
}

# NACL rules for public subnet
resource "aws_network_acl_rule" "PublicInboundHTTP" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = var.http_port
  to_port        = var.http_port
}

resource "aws_network_acl_rule" "PublicInboundHTTPS" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = var.https_port
  to_port        = var.https_port
}

resource "aws_network_acl_rule" "PublicInboundSSH" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.ssh_cidr_blocks
  from_port      = var.ssh_port
  to_port        = var.ssh_port
}

# Allow all outbound traffic
resource "aws_network_acl_rule" "PublicOutbound" {
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# Create a NACL for the Private Subnet
resource "aws_network_acl" "PrivateSubnetNACL" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = var.private_nacl_name
  }
}

# Allow inbound traffic from the public subnet
resource "aws_network_acl_rule" "PrivateInboundFromPublic" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.public_subnet_cidr
  from_port      = 0
  to_port        = 65535
}

# Allow outbound traffic to the public subnet
resource "aws_network_acl_rule" "PrivateOutboundToPublic" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = var.public_subnet_cidr
  from_port      = 0
  to_port        = 65535
}

# Allow outbound traffic to the internet
resource "aws_network_acl_rule" "PrivateOutboundToInternet" {
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
  rule_number    = 210
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# Associate the Public Subnet with the Public NACL
resource "aws_network_acl_association" "PublicSubnetAssociation" {
  subnet_id      = aws_subnet.PublicSubnet.id
  network_acl_id = aws_network_acl.PublicSubnetNACL.id
}

# Associate the Private Subnet with the Private NACL
resource "aws_network_acl_association" "PrivateSubnetAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  network_acl_id = aws_network_acl.PrivateSubnetNACL.id
}