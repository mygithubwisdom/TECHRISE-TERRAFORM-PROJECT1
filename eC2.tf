# ec2.tf
resource "aws_instance" "Publicweb_server" {
  ami                         = var.public_instance_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.PublicSubnet.id
  security_groups             = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = var.public_key_name
  
  # Reference the Nginx installation script
  user_data = file("scripts/install_nginx.sh")

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  tags = {
    Name = var.public_instance_name
  }
}

# Launch an EC2 instance in the Private Subnet
resource "aws_instance" "PrivateDB_server" {
  ami                         = var.private_instance_ami
  instance_type               = var.instance_type
  # Reference the PostgreSQL installation script
  user_data                   = file("scripts/install_postgresql.sh")
  key_name                    = var.private_key_name

  subnet_id                   = aws_subnet.PrivateSubnet.id
  security_groups             = [aws_security_group.private_sg.id] # Attach the private security group
  associate_public_ip_address = true 
 
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }

  tags = {
    Name = var.private_instance_name
  }
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "NAT_EIP" {
  tags = {
    Name = var.nat_eip_name
  }
}

# Create a NAT Gateway in the Public Subnet
resource "aws_nat_gateway" "NATGateway" {
  allocation_id = aws_eip.NAT_EIP.id
  subnet_id     = aws_subnet.PublicSubnet.id

  tags = {
    Name = var.nat_gateway_name
  }

  # Ensure the NAT Gateway depends on the Internet Gateway
  depends_on = [aws_internet_gateway.IGW]
}

# Update the Private Route Table to route traffic through the NAT Gateway
resource "aws_route" "PrivateRouteToNAT" {
  route_table_id         = aws_route_table.PrivateRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NATGateway.id
}